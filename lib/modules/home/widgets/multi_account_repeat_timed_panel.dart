import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_json_transfer_actions.dart';
import 'package:oasx/modules/home/widgets/task_catalog_row_layout.dart';
import 'package:oasx/modules/home/widgets/multi_account_task_list_layout.dart';
import 'package:oasx/modules/home/widgets/shared_public_account_copy_dialog.dart';
import 'package:oasx/modules/home/widgets/account_management_dialogs.dart';
import 'package:oasx/modules/home/widgets/task_status_row.dart';
import 'package:oasx/modules/home/widgets/script_schedule_refresh.dart';
import 'package:oasx/translation/i18n_content.dart';

enum _AccountTaskFilter { all, enabled, disabled }

/// 多账号多任务定时的独立配置面板。
class MultiAccountRepeatTimedPanel extends StatefulWidget {
  const MultiAccountRepeatTimedPanel({
    super.key,
    required this.controller,
    required this.scriptModel,
    required this.onBack,
  });

  final HomeDashboardController controller;
  final ScriptModel scriptModel;
  final Future<void> Function() onBack;

  String get scriptName => scriptModel.name;

  @override
  State<MultiAccountRepeatTimedPanel> createState() =>
      _MultiAccountRepeatTimedPanelState();
}

class _MultiAccountRepeatTimedPanelState
    extends State<MultiAccountRepeatTimedPanel> {
  late Future<Map<String, dynamic>> _stateFuture;
  late final Future<Map<String, List<String>>> _menuFuture;
  int _selectedAccount = 1;
  final Rxn<Map<String, dynamic>> _liveState = Rxn<Map<String, dynamic>>();
  final ScriptService _scriptService = Get.find<ScriptService>();
  Worker? _overviewWorker;
  Worker? _nativeScheduleWorker;
  Map<String, dynamic>? _activeOverviewTask;
  final Set<String> _loadingTasks = <String>{};
  final Set<String> _hiddenTaskIds = <String>{};
  final Set<String> _expandedCatalogGroups = <String>{};
  final Set<String> _togglingCatalogTasks = <String>{};
  final Map<String, bool> _enabledOverrides = <String, bool>{};
  final TextEditingController _taskSearchController = TextEditingController();
  int _stateGeneration = 0;
  String _taskSearchQuery = '';
  bool _showAllTasks = false;
  _AccountTaskFilter _taskFilter = _AccountTaskFilter.all;

  @override
  void initState() {
    super.initState();
    _stateFuture = ApiClient().getMultiAccountRepeatTimedAccounts(
      scriptName: widget.scriptName,
    );
    _watchState(_stateFuture);
    _menuFuture = ApiClient().getScriptMenu();
    _bindOverviewPush();
    _bindNativeScheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant MultiAccountRepeatTimedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptName == widget.scriptName) {
      return;
    }
    _selectedAccount = 1;
    _bindNativeScheduleRefresh();
    _activeOverviewTask = null;
    _clearTaskListState();
    _reload();
  }

  @override
  void dispose() {
    _overviewWorker?.dispose();
    _nativeScheduleWorker?.dispose();
    _taskSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTaskToolbar(context),
        const SizedBox(height: 10),
        Expanded(
          child: Obx(() {
            final data = _liveState.value;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildStateContent(data);
          }),
        ),
      ],
    );
  }

  Widget _buildStateContent(Map<String, dynamic> data) {
    final accounts = _maps(data['accounts']);
    if (accounts.isEmpty) {
      return _buildEmpty(context);
    }
    if (_selectedAccount > accounts.length) {
      _selectedAccount = accounts.length;
    }
    final account = accounts[_selectedAccount - 1];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, accounts),
          const SizedBox(height: 12),
          _buildTaskList(context, account),
        ],
      ),
    );
  }

  Widget _buildTaskToolbar(BuildContext context) {
    final canQuickSchedule =
        widget.controller.isTaskEnabled(
          widget.scriptModel,
          'MultiAccountRepeatTimed',
        ) &&
        widget.controller.canQuickScheduleTask(
          widget.scriptModel,
          'MultiAccountRepeatTimed',
        );
    return Row(
      children: [
        IconButton(
          tooltip: '返回'.tr,
          onPressed: () async => widget.onBack(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '多账号多任务定时'.tr,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: I18n.homeQuickRun.tr,
          onPressed: canQuickSchedule
              ? () => _quickSchedule(runNow: true)
              : null,
          icon: const Icon(Icons.flash_on_rounded, size: 18),
        ),
        IconButton(
          tooltip: I18n.homeQuickWait.tr,
          onPressed: canQuickSchedule
              ? () => _quickSchedule(runNow: false)
              : null,
          icon: const Icon(Icons.schedule_rounded, size: 18),
        ),
        TaskJsonTransferActions(
          configName: widget.scriptName,
          taskName: 'MultiAccountRepeatTimed',
          onImported: _reloadAfterImport,
        ),
      ],
    );
  }

  Future<void> _reloadAfterImport() async {
    _reload();
  }

  Future<void> _quickSchedule({required bool runNow}) async {
    final success = await widget.controller.quickScheduleTask(
      scriptName: widget.scriptName,
      taskName: 'MultiAccountRepeatTimed',
      runNow: runNow,
    );
    if (success) {
      Get.snackbar(I18n.success.tr, '多账号多任务定时'.tr);
    }
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('尚未添加运行账号'.tr),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showPublicAccounts,
                icon: const Icon(Icons.groups_rounded),
                label: Text('公共账号库'.tr),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _showAddTaskAccount,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text('添加账号'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<Map<String, dynamic>> accounts,
  ) {
    return Card(
      // 与配置页的调度器、每日琐事等分组使用相同的浅紫底色。
      // 与每日琐事 Args 中 ExpansionTileItem 的参数保持一致。
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.24),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('账号管理'.tr, style: Theme.of(context).textTheme.titleSmall),
                buildAccountManagementButton(
                  onPressed: _showPublicAccounts,
                  icon: Icons.groups_rounded,
                  label: '公共账号库'.tr,
                ),
                buildAccountManagementButton(
                  onPressed: _showPublicSettings,
                  icon: Icons.settings_rounded,
                  label: '公共配置'.tr,
                ),
                buildAccountManagementButton(
                  onPressed: _showAddTaskAccount,
                  icon: Icons.person_add_alt_1_rounded,
                  label: '添加账号'.tr,
                  filled: true,
                ),
                buildAccountManagementButton(
                  onPressed: () => _showDeleteTaskAccounts(accounts),
                  icon: Icons.person_remove_outlined,
                  label: '删除账号'.tr,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 10),
            Text('运行账号'.tr, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            _buildAccountSelector(context, accounts),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, Map<String, dynamic> account) {
    final accountIndex = account['index'] as int? ?? _selectedAccount;
    final allTasks = _maps(account['tasks']);
    final enabledTasks = allTasks
        .where((task) => _taskEnabled(accountIndex, task))
        .toList();
    _pruneHiddenTaskIds(enabledTasks, accountIndex);
    final tasks = enabledTasks
        .where(
          (task) => !_hiddenTaskIds.contains(
            _taskRowId(accountIndex, '${task['task_name'] ?? ''}'.trim()),
          ),
        )
        .where(_matchesTaskQuery)
        .toList();
    return Card(
      // 与配置页的调度器、每日琐事等分组使用相同的浅紫底色。
      // 与每日琐事 Args 中 ExpansionTileItem 的参数保持一致。
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.24),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_accountLabel(account)}：${'任务列表'.tr}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '删除账号'.tr,
                  onPressed: () => _deleteTaskAccount(accountIndex),
                  icon: const Icon(Icons.person_remove_outlined),
                ),
                FilledButton.icon(
                  onPressed: () => _showEnableTasksDialog(accountIndex),
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: Text('启用任务'.tr),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('总览'.tr),
                  selected: !_showAllTasks,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _showAllTasks = false),
                ),
                ChoiceChip(
                  label: Text('任务'.tr),
                  selected: _showAllTasks,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _showAllTasks = true),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTaskSearchToolbar(),
            const SizedBox(height: 10),
            SizedBox(
              // 定时任务列表至少容纳十项；超过十项后只滚动该列表。
              height: multiAccountTaskListMinHeight,
              child: _showAllTasks
                  ? _buildAllTaskCatalog(context, account, allTasks)
                  : _buildEnabledTaskList(context, tasks, accountIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnabledTaskList(
    BuildContext context,
    List<Map<String, dynamic>> tasks,
    int accountIndex,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(_taskSearchQuery.isEmpty ? '当前账号尚未添加任务'.tr : '未找到匹配任务'.tr),
      );
    }
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final taskName = '${task['task_name'] ?? ''}'.trim();
        final taskDisplayName = '${task['task_display_name'] ?? taskName}'
            .trim();
        final status = '${task['status'] ?? 'pending'}';
        final nextRun = '${task['next_run'] ?? ''}'.trim();
        final loading = _loadingTasks.contains(taskName);
        final activeAccountIndex = _activeOverviewTask?['account_index'];
        final activeTaskName = '${_activeOverviewTask?['task_name'] ?? ''}';
        final isRunning =
            activeAccountIndex == accountIndex && activeTaskName == taskName;
        final scheduleStatus = isRunning
            ? 'running'
            : '${task['schedule_status'] ?? status}';
        final taskType = switch (scheduleStatus) {
          'running' => TaskStatusType.running,
          'pending' => TaskStatusType.pending,
          _ => TaskStatusType.waiting,
        };
        final taskView = TaskStatusViewData(
          rowId: _taskRowId(accountIndex, taskName),
          name: taskName,
          displayName: taskDisplayName,
          type: taskType,
          timeText: nextRun,
        );
        return TaskStatusRow(
          key: ValueKey(taskView.rowId),
          controller: widget.controller,
          sourceScriptName: widget.scriptName,
          task: taskView,
          canQuickSchedule: status != 'running' && !loading,
          quickScheduleLocked: loading,
          onSetNextRun: (name, value) =>
              _setAccountTaskNextRun(accountIndex, name, value),
          onQuickRun: (_) =>
              _quickScheduleTask(accountIndex, taskName, runNow: true),
          onQuickWait: (_) =>
              _quickScheduleTask(accountIndex, taskName, runNow: false),
          onEditTask: (_) =>
              _showTaskSettings(accountIndex, taskName, taskDisplayName),
          onDisableTask: (_) => _disableTaskBySwipe(accountIndex, taskName),
          onDismissed: (rowId) => _hideTaskLocally(rowId),
          dragEnabled: false,
          swipeEnabled: status != 'running' && !loading,
          activeDragPayload: null,
        );
      },
    );
  }

  Widget _buildAllTaskCatalog(
    BuildContext context,
    Map<String, dynamic> account,
    List<Map<String, dynamic>> configuredTasks,
  ) {
    final accountIndex = account['index'] as int? ?? _selectedAccount;
    final configured = <String, Map<String, dynamic>>{
      for (final task in configuredTasks)
        _normalizeTaskName('${task['task_name'] ?? ''}'): task,
    };
    return FutureBuilder<Map<String, List<String>>>(
      future: _menuFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sections =
            snapshot.data?.entries
                .map(
                  (entry) => MapEntry(
                    entry.key,
                    entry.value.map((name) => name.trim()).where((name) {
                      if (name.isEmpty || !_matchesCatalogQuery(name)) {
                        return false;
                      }
                      return _matchesTaskFilter(
                        _taskEnabled(
                          accountIndex,
                          _configuredTask(configured, name),
                          taskName: name,
                        ),
                      );
                    }).toList(),
                  ),
                )
                .where((entry) => entry.value.isNotEmpty)
                .toList() ??
            const <MapEntry<String, List<String>>>[];
        if (sections.isEmpty) {
          return Center(child: Text('未找到匹配任务'.tr));
        }
        return ListView.separated(
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final section = sections[index];
            return _buildCatalogSection(
              context,
              accountIndex,
              section.key,
              section.value,
              configured,
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogSection(
    BuildContext context,
    int accountIndex,
    String groupName,
    List<String> taskNames,
    Map<String, Map<String, dynamic>> configured,
  ) {
    final expanded =
        _taskSearchQuery.isNotEmpty ||
        _expandedCatalogGroups.contains(groupName);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: expanded
          ? Theme.of(context).cardColor
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _taskSearchQuery.isNotEmpty
                ? null
                : () => setState(() {
                    if (expanded) {
                      _expandedCatalogGroups.remove(groupName);
                    } else {
                      _expandedCatalogGroups.add(groupName);
                    }
                  }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator_rounded),
                  const SizedBox(width: 10),
                  Expanded(child: Text(groupName.tr)),
                  Text('${taskNames.length}'),
                  const SizedBox(width: 10),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (var index = 0; index < taskNames.length; index++) ...[
                    if (index > 0) const Divider(height: 1),
                    _buildCatalogTaskRow(
                      context,
                      accountIndex,
                      groupName,
                      taskNames[index],
                      _configuredTask(configured, taskNames[index]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCatalogTaskRow(
    BuildContext context,
    int accountIndex,
    String groupName,
    String taskName,
    Map<String, dynamic>? configured,
  ) {
    final enabled = _taskEnabled(accountIndex, configured);
    final loading = _togglingCatalogTasks.contains(taskName);
    final isScriptTask = groupName == I18n.script;
    final supportsEnable = !isScriptTask || taskName == 'Restart';
    final canQuick = enabled && !loading && taskName != 'Restart';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TaskCatalogSplitRow(
        scrollKey: PageStorageKey<String>(
          'multi-account-timed-task-row-$accountIndex-$taskName',
        ),
        taskLabel: Text(
          taskName.tr,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        supportsEnable: supportsEnable,
        enabled: enabled,
        loading: loading,
        onToggleEnabled: loading
            ? null
            : (value) => _toggleCatalogTask(accountIndex, taskName, value),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (supportsEnable)
              TaskCatalogIconOnlyButton(
                icon: Icons.flash_on_rounded,
                tooltip: I18n.homeQuickRun.tr,
                onPressed: canQuick
                    ? () => _quickScheduleTask(
                        accountIndex,
                        taskName,
                        runNow: true,
                      )
                    : null,
              ),
            if (supportsEnable)
              TaskCatalogIconOnlyButton(
                icon: Icons.schedule_rounded,
                tooltip: I18n.homeQuickWait.tr,
                onPressed: canQuick
                    ? () => _quickScheduleTask(
                        accountIndex,
                        taskName,
                        runNow: false,
                      )
                    : null,
              ),
            TaskCatalogIconOnlyButton(
              icon: Icons.tune_rounded,
              tooltip: I18n.homeOpenTaskParams.tr,
              onPressed: () =>
                  _showTaskSettings(accountIndex, taskName, taskName.tr),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesCatalogQuery(String taskName) {
    if (_taskSearchQuery.isEmpty) return true;
    final query = _taskSearchQuery;
    final localized = taskName.tr.toLowerCase();
    return taskName.toLowerCase().contains(query) || localized.contains(query);
  }

  String _normalizeTaskName(String taskName) {
    return taskName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Map<String, dynamic>? _configuredTask(
    Map<String, Map<String, dynamic>> configured,
    String taskName,
  ) {
    return configured[_normalizeTaskName(taskName)];
  }

  bool _taskEnabled(
    int accountIndex,
    Map<String, dynamic>? task, {
    String? taskName,
  }) {
    final resolvedName = (taskName ?? '${task?['task_name'] ?? ''}').trim();
    final key = '$accountIndex:${_normalizeTaskName(resolvedName)}';
    final override = _enabledOverrides[key];
    if (override != null) return override;
    final value = task?['enabled'];
    return value == true || '$value'.toLowerCase() == 'true';
  }

  Future<void> _toggleCatalogTask(
    int accountIndex,
    String taskName,
    bool enable,
  ) async {
    final key = '$accountIndex:${_normalizeTaskName(taskName)}';
    if (_togglingCatalogTasks.contains(taskName)) return;
    setState(() => _togglingCatalogTasks.add(taskName));
    final ok = enable
        ? await ApiClient().addMultiAccountRepeatTimedTask(
            scriptName: widget.scriptName,
            accountIndex: accountIndex,
            taskName: taskName,
          )
        : await ApiClient().setMultiAccountRepeatTimedTaskEnable(
            scriptName: widget.scriptName,
            accountIndex: accountIndex,
            taskName: taskName,
            enable: false,
          );
    if (!mounted) return;
    setState(() {
      _togglingCatalogTasks.remove(taskName);
      if (ok) _enabledOverrides[key] = enable;
    });
    if (ok) _reload();
  }

  Widget _buildTaskSearchToolbar() {
    return Row(
      children: [
        Expanded(child: _buildTaskSearchField()),
        if (_showAllTasks) ...[
          const SizedBox(width: 8),
          PopupMenuButton<_AccountTaskFilter>(
            tooltip: _taskFilterLabel(_taskFilter),
            initialValue: _taskFilter,
            onSelected: (value) => setState(() => _taskFilter = value),
            itemBuilder: (context) => _AccountTaskFilter.values
                .map(
                  (value) => PopupMenuItem<_AccountTaskFilter>(
                    value: value,
                    child: Text(_taskFilterLabel(value)),
                  ),
                )
                .toList(),
            icon: Icon(
              Icons.filter_list_rounded,
              color: _taskFilter == _AccountTaskFilter.all
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTaskSearchField() {
    return TextField(
      controller: _taskSearchController,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: '搜索任务'.tr,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => setState(() {
        _taskSearchQuery = value.trim().toLowerCase();
      }),
    );
  }

  String _taskFilterLabel(_AccountTaskFilter filter) {
    return switch (filter) {
      _AccountTaskFilter.all => '全部任务'.tr,
      _AccountTaskFilter.enabled => '已启用'.tr,
      _AccountTaskFilter.disabled => '未启用'.tr,
    };
  }

  bool _matchesTaskFilter(bool enabled) {
    return switch (_taskFilter) {
      _AccountTaskFilter.all => true,
      _AccountTaskFilter.enabled => enabled,
      _AccountTaskFilter.disabled => !enabled,
    };
  }

  bool _matchesTaskQuery(Map<String, dynamic> task) {
    if (_taskSearchQuery.isEmpty) return true;
    final taskName = '${task['task_name'] ?? ''}'.trim().toLowerCase();
    final displayName = '${task['task_display_name'] ?? taskName}'
        .trim()
        .toLowerCase();
    return taskName.contains(_taskSearchQuery) ||
        displayName.contains(_taskSearchQuery);
  }

  String _taskRowId(int accountIndex, String taskName) {
    return 'account:$accountIndex:$taskName';
  }

  void _hideTaskLocally(String rowId) {
    if (!mounted) return;
    setState(() => _hiddenTaskIds.add(rowId));
  }

  void _pruneHiddenTaskIds(List<Map<String, dynamic>> tasks, int accountIndex) {
    final activeIds = tasks
        .map(
          (task) =>
              _taskRowId(accountIndex, '${task['task_name'] ?? ''}'.trim()),
        )
        .toSet();
    final staleIds = _hiddenTaskIds
        .where((rowId) => rowId.startsWith('account:$accountIndex:'))
        .where((rowId) => !activeIds.contains(rowId))
        .toList();
    if (staleIds.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _hiddenTaskIds.removeAll(staleIds));
    });
  }

  void _clearTaskListState() {
    _hiddenTaskIds.clear();
    _taskSearchController.clear();
    _taskSearchQuery = '';
    _enabledOverrides.clear();
  }

  List<Map<String, dynamic>> _maps(dynamic value) {
    return value is List
        ? value
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];
  }

  String _accountLabel(Map<String, dynamic> account) {
    final identifier = '${account['public_account_identifier'] ?? ''}'.trim();
    final character = '${account['character'] ?? ''}'.trim();
    final server = '${account['svr'] ?? ''}'.trim();
    final title = [
      character,
      server,
    ].where((item) => item.isNotEmpty).join('-');
    if (identifier.isEmpty) return title;
    return title.isEmpty ? identifier : '$identifier：$title';
  }

  /// 账号较多时使用可搜索的选择器，避免横向滑动几十个账号标签。
  Widget _buildAccountSelector(
    BuildContext context,
    List<Map<String, dynamic>> accounts,
  ) {
    final currentAccount = accounts.firstWhere(
      (account) => account['index'] == _selectedAccount,
      orElse: () => accounts.first,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () async {
          final selected = await _showAccountPicker(accounts);
          if (selected != null && mounted) {
            setState(() {
              _selectedAccount = selected;
              _clearTaskListState();
            });
          }
        },
        icon: const Icon(Icons.manage_search_rounded, size: 18),
        label: Text(
          '${'选择账号'.tr}（${accounts.length}）：${_accountLabel(currentAccount)}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _accountPickerDetail(Map<String, dynamic> account) {
    final loginAccount = '${account['account'] ?? ''}'.trim();
    final platform = account['apple_or_android'] == false ? '苹果'.tr : '安卓'.tr;
    return '账号：${loginAccount.isEmpty ? '-' : loginAccount} · 平台：$platform';
  }

  Future<int?> _showAccountPicker(List<Map<String, dynamic>> accounts) async {
    var keyword = '';
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final query = keyword.trim().toLowerCase();
          final visibleAccounts = accounts.where((account) {
            final searchText =
                '${_accountLabel(account)} ${account['account'] ?? ''}'
                    .toLowerCase();
            return query.isEmpty || searchText.contains(query);
          }).toList();
          return AlertDialog(
            title: Text('选择运行账号'.tr),
            content: SizedBox(
              width: 520,
              height: 520,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    onChanged: (value) => setDialogState(() => keyword = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: '搜索账号、角色名或服务器'.tr,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: visibleAccounts.isEmpty
                        ? Center(child: Text('未找到匹配账号'.tr))
                        : ListView.separated(
                            itemCount: visibleAccounts.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final account = visibleAccounts[index];
                              final accountIndex =
                                  account['index'] as int? ?? 0;
                              return ListTile(
                                selected: accountIndex == _selectedAccount,
                                leading: Icon(
                                  accountIndex == _selectedAccount
                                      ? Icons.check_circle_rounded
                                      : Icons.account_circle_outlined,
                                ),
                                title: Text(_accountLabel(account)),
                                subtitle: Text(_accountPickerDetail(account)),
                                onTap: () => Navigator.of(
                                  dialogContext,
                                ).pop(accountIndex),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(I18n.cancel.tr),
              ),
            ],
          );
        },
      ),
    );
  }

  String _publicAccountDetail(Map<String, dynamic> account) {
    final character = '${account['character'] ?? ''}'.trim();
    final server = '${account['svr'] ?? ''}'.trim();
    final loginAccount = '${account['account'] ?? ''}'.trim();
    final platform = account['apple_or_android'] == false ? '苹果'.tr : '安卓'.tr;
    String valueOrPlaceholder(String value) => value.isEmpty ? '-' : value;
    return '角色名：${valueOrPlaceholder(character)} · 服务器：${valueOrPlaceholder(server)}\n'
        '账号：${valueOrPlaceholder(loginAccount)} · 平台：$platform';
  }

  Future<void> _showPublicAccounts() async {
    await showPublicAccountLibraryDialog(
      context: context,
      loadAccounts: () async => _maps(
        (await ApiClient().getMultiAccountRepeatTimedPublicAccounts(
          scriptName: widget.scriptName,
        ))['accounts'],
      ),
      onDelete: (identifier) =>
          ApiClient().deleteMultiAccountRepeatTimedPublicAccount(
            scriptName: widget.scriptName,
            identifier: identifier,
          ),
      onEdit: _editPublicAccount,
      onAdd: () async {
        final identifier = await _askText('新增公共账号'.tr, '账号标识'.tr);
        if (identifier == null || identifier.trim().isEmpty) return false;
        return ApiClient().addMultiAccountRepeatTimedPublicAccount(
          scriptName: widget.scriptName,
          identifier: identifier.trim(),
        );
      },
      detailBuilder: _publicAccountDetail,
      onCopy: (accounts) => showSharedPublicAccountCopyDialog(
        context: context,
        sourceScriptName: widget.scriptName,
        accounts: accounts,
      ),
    );
    _reload();
  }

  Future<bool> _editPublicAccount(Map<String, dynamic> account) async {
    final originalIdentifier = '${account['identifier'] ?? ''}';
    final identifier = TextEditingController(text: originalIdentifier);
    final character = TextEditingController(
      text: '${account['character'] ?? ''}',
    );
    final server = TextEditingController(text: '${account['svr'] ?? ''}');
    final login = TextEditingController(text: '${account['account'] ?? ''}');
    final alias = TextEditingController(
      text: '${account['account_alias'] ?? ''}',
    );
    var apple = account['apple_or_android'] != false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('编辑公共账号'.tr),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: identifier,
                    decoration: InputDecoration(labelText: '账号标识'.tr),
                  ),
                  TextField(
                    controller: character,
                    decoration: InputDecoration(labelText: '角色名'.tr),
                  ),
                  TextField(
                    controller: server,
                    decoration: InputDecoration(labelText: '服务器'.tr),
                  ),
                  TextField(
                    controller: login,
                    decoration: InputDecoration(labelText: '账号'.tr),
                  ),
                  TextField(
                    controller: alias,
                    decoration: InputDecoration(labelText: '账号别名'.tr),
                  ),
                  SwitchListTile(
                    value: apple,
                    onChanged: (value) => setDialogState(() => apple = value),
                    title: Text('苹果或安卓'.tr),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton(
              onPressed: () async {
                var currentIdentifier = originalIdentifier;
                final fields = <(String, String, dynamic)>[
                  ('identifier', 'string', identifier.text.trim()),
                  ('character', 'string', character.text.trim()),
                  ('svr', 'string', server.text.trim()),
                  ('account', 'string', login.text.trim()),
                  ('account_alias', 'string', alias.text.trim()),
                  ('apple_or_android', 'boolean', apple),
                ];
                for (final field in fields) {
                  final ok = await ApiClient()
                      .putMultiAccountRepeatTimedPublicAccountValue(
                        scriptName: widget.scriptName,
                        identifier: currentIdentifier,
                        field: field.$1,
                        type: field.$2,
                        value: field.$3,
                      );
                  if (!ok) return;
                  if (field.$1 == 'identifier') {
                    currentIdentifier = field.$3 as String;
                  }
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
    identifier.dispose();
    character.dispose();
    server.dispose();
    login.dispose();
    alias.dispose();
    if (saved == true) {
      _reload();
      return true;
    }
    return false;
  }

  Future<void> _showAddTaskAccount() async {
    final library = await ApiClient().getMultiAccountRepeatTimedPublicAccounts(
      scriptName: widget.scriptName,
    );
    final state = await _stateFuture;
    if (!mounted) return;
    final used = _maps(
      state['accounts'],
    ).map((item) => '${item['public_account_identifier'] ?? ''}').toSet();
    final choices = _maps(
      library['accounts'],
    ).where((item) => !used.contains('${item['identifier'] ?? ''}')).toList();
    final selected = await showMultiAccountPickerDialog(
      context: context,
      choices: choices,
      detailBuilder: _publicAccountDetail,
    );
    if (selected == null || selected.isEmpty) return;
    for (final identifier in selected) {
      await ApiClient().addMultiAccountRepeatTimedAccount(
        scriptName: widget.scriptName,
        publicAccountIdentifier: identifier,
      );
    }
    _reload();
  }

  Future<void> _showDeleteTaskAccounts(
    List<Map<String, dynamic>> accounts,
  ) async {
    final indexes = await showBatchAccountDeleteDialog(
      context: context,
      accounts: accounts,
      titleBuilder: _accountLabel,
      detailBuilder: _accountPickerDetail,
    );
    if (indexes == null || indexes.isEmpty || !mounted) return;
    final confirmed = await _confirm(
      '确认批量删除'.tr,
      '只会删除运行账号列表中的账号，不会删除公共账号库中的账号。是否继续？'.tr,
    );
    if (confirmed != true) return;
    final sortedIndexes = [...indexes]..sort((a, b) => b.compareTo(a));
    for (final accountIndex in sortedIndexes) {
      await ApiClient().deleteMultiAccountRepeatTimedAccount(
        scriptName: widget.scriptName,
        accountIndex: accountIndex,
      );
    }
    _selectedAccount = 1;
    _reload();
  }

  Future<void> _deleteTaskAccount(int accountIndex) async {
    final confirmed = await _confirm(
      '删除账号'.tr,
      '删除后会同时清除该账号下的任务及私有配置，是否继续？'.tr,
    );
    if (confirmed != true) return;
    if (await ApiClient().deleteMultiAccountRepeatTimedAccount(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
    )) {
      _selectedAccount = 1;
      _reload();
    }
  }

  Future<void> _showEnableTasksDialog(int accountIndex) async {
    final state = await _stateFuture;
    if (!mounted) return;
    final account = _maps(state['accounts']).firstWhere(
      (item) => item['index'] == accountIndex,
      orElse: () => <String, dynamic>{},
    );
    final enabledTaskNames = _maps(account['tasks'])
        .where((task) => _taskEnabled(accountIndex, task))
        .map((task) => _normalizeTaskName('${task['task_name'] ?? ''}'))
        .toSet();
    final selectedTaskNames = <String>{};
    final searchController = TextEditingController();
    var searchQuery = '';
    var filter = _AccountTaskFilter.all;
    try {
      final selected = await showDialog<List<String>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('${_accountLabel(account)}：${'启用任务'.tr}'),
            content: SizedBox(
              width: 620,
              height: 620,
              child: FutureBuilder<Map<String, List<String>>>(
                future: _menuFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final query = searchQuery.trim().toLowerCase();
                  // 按 OAS 菜单的分类及分类内顺序平铺显示，不按名称重新排序。
                  final taskNames = snapshot.data!.values
                      .expand((items) => items)
                      .map((item) => item.trim())
                      .where((taskName) {
                        if (taskName.isEmpty ||
                            taskName == 'Script' ||
                            taskName == 'Restart' ||
                            taskName == 'GlobalGame' ||
                            taskName.startsWith('MultiAccount')) {
                          return false;
                        }
                        final alreadyEnabled = enabledTaskNames.contains(
                          _normalizeTaskName(taskName),
                        );
                        if (filter == _AccountTaskFilter.enabled &&
                            !alreadyEnabled) {
                          return false;
                        }
                        if (filter == _AccountTaskFilter.disabled &&
                            alreadyEnabled) {
                          return false;
                        }
                        return query.isEmpty ||
                            taskName.toLowerCase().contains(query) ||
                            taskName.tr.toLowerCase().contains(query);
                      })
                      .toSet()
                      .toList();
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                isDense: true,
                                prefixIcon: const Icon(Icons.search_rounded),
                                hintText: '搜索任务'.tr,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) =>
                                  setDialogState(() => searchQuery = value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<_AccountTaskFilter>(
                            tooltip: _taskFilterLabel(filter),
                            initialValue: filter,
                            onSelected: (value) =>
                                setDialogState(() => filter = value),
                            itemBuilder: (context) => _AccountTaskFilter.values
                                .map(
                                  (value) => PopupMenuItem<_AccountTaskFilter>(
                                    value: value,
                                    child: Text(_taskFilterLabel(value)),
                                  ),
                                )
                                .toList(),
                            icon: Icon(
                              Icons.filter_list_rounded,
                              color: filter == _AccountTaskFilter.all
                                  ? null
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '已启用任务仅供查看；可多选未启用任务进行启用。已停用任务会保留私有配置和运行记录。'.tr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: taskNames.isEmpty
                            ? Center(child: Text('没有可启用的任务'.tr))
                            : ListView.separated(
                                itemCount: taskNames.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final taskName = taskNames[index];
                                  final alreadyEnabled = enabledTaskNames
                                      .contains(_normalizeTaskName(taskName));
                                  return TaskCatalogSplitRow(
                                    scrollKey: ValueKey(
                                      'timed-enable-$accountIndex-$taskName',
                                    ),
                                    taskLabel: Text(
                                      taskName.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    supportsEnable: true,
                                    enabled:
                                        alreadyEnabled ||
                                        selectedTaskNames.contains(taskName),
                                    loading: false,
                                    onToggleEnabled: alreadyEnabled
                                        ? null
                                        : (enabled) => setDialogState(() {
                                            if (enabled) {
                                              selectedTaskNames.add(taskName);
                                            } else {
                                              selectedTaskNames.remove(
                                                taskName,
                                              );
                                            }
                                          }),
                                    trailing: const SizedBox.shrink(),
                                    trailingExtent: 0,
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(I18n.cancel.tr),
              ),
              FilledButton.icon(
                onPressed: selectedTaskNames.isEmpty
                    ? null
                    : () => Navigator.of(
                        dialogContext,
                      ).pop(selectedTaskNames.toList()),
                icon: const Icon(Icons.playlist_add_rounded),
                label: Text('启用（${selectedTaskNames.length}）'.tr),
              ),
            ],
          ),
        ),
      );
      if (selected == null || selected.isEmpty) return;
      for (final taskName in selected) {
        final ok = await ApiClient().addMultiAccountRepeatTimedTask(
          scriptName: widget.scriptName,
          accountIndex: accountIndex,
          taskName: taskName,
        );
        if (!ok) return;
      }
      if (mounted) _reload();
    } finally {
      searchController.dispose();
    }
  }

  Future<void> _setAccountTaskNextRun(
    int accountIndex,
    String taskName,
    String nextRun,
  ) async {
    final ok = await ApiClient().putMultiAccountRepeatTimedTaskArg(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
      groupName: 'scheduler',
      argumentName: 'next_run',
      type: 'date_time',
      value: nextRun,
    );
    if (ok) _reload();
  }

  Future<void> _quickScheduleTask(
    int accountIndex,
    String taskName, {
    required bool runNow,
  }) async {
    if (_loadingTasks.contains(taskName)) return;
    setState(() => _loadingTasks.add(taskName));
    final ok = await ApiClient().quickScheduleMultiAccountRepeatTimedTask(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
      runNow: runNow,
    );
    if (!mounted) return;
    setState(() => _loadingTasks.remove(taskName));
    if (ok) _reload();
  }

  Future<bool> _disableTaskBySwipe(int accountIndex, String taskName) {
    return ApiClient().setMultiAccountRepeatTimedTaskEnable(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
      enable: false,
    );
  }

  Future<void> _showPublicSettings() async {
    final data = await ApiClient().getMultiAccountRepeatTimedPublicArgs(
      scriptName: widget.scriptName,
    );
    if (!mounted || data.isEmpty) return;
    final args = Get.find<ArgsController>();
    await args.loadGroupsFromData(
      config: widget.scriptName,
      task: 'MultiAccountRepeatTimed',
      json: data,
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) {
        return ApiClient().putMultiAccountRepeatTimedPublicArg(
          scriptName: config,
          groupName: group,
          argumentName: argument,
          type: type,
          value: value,
        );
      },
    );
    if (!mounted) return;
    await _showArgsDialog(args, '多账号多任务定时公共配置'.tr);
  }

  Future<void> _showTaskSettings(
    int accountIndex,
    String taskName,
    String taskDisplayName,
  ) async {
    setState(() => _loadingTasks.add(taskName));
    final data = await ApiClient().getMultiAccountRepeatTimedTaskArgs(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
    );
    if (!mounted || data.isEmpty) {
      if (mounted) setState(() => _loadingTasks.remove(taskName));
      return;
    }
    final args = Get.find<ArgsController>();
    await args.loadGroupsFromData(
      config: widget.scriptName,
      task: taskName,
      json: data,
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) {
        return ApiClient().putMultiAccountRepeatTimedTaskArg(
          scriptName: config,
          accountIndex: accountIndex,
          taskName: task,
          groupName: group,
          argumentName: argument,
          type: type,
          value: value,
        );
      },
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 720,
          height: 680,
          child: Column(
            children: [
              ListTile(
                title: Text('$taskDisplayName：${'账号私有配置'.tr}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: '恢复默认配置'.tr,
                      onPressed: () async {
                        final ok = await ApiClient()
                            .resetMultiAccountRepeatTimedTaskPrivateConfig(
                              scriptName: widget.scriptName,
                              accountIndex: accountIndex,
                              taskName: taskName,
                            );
                        if (ok && dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                    ),
                    IconButton(
                      tooltip: '复制到其他账号'.tr,
                      onPressed: () => _showCopyTaskConfigDialog(
                        accountIndex,
                        taskName,
                        taskDisplayName,
                      ),
                      icon: const Icon(Icons.content_copy_rounded),
                    ),
                    IconButton(
                      tooltip: '关闭'.tr,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Args(
                  scriptName: widget.scriptName,
                  taskName: taskName,
                  stagingMode: true,
                  onCancel: () async {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await args.discardDraftChanges();
    if (mounted) {
      setState(() => _loadingTasks.remove(taskName));
      _reload();
    }
  }

  Future<void> _showCopyTaskConfigDialog(
    int sourceAccountIndex,
    String taskName,
    String taskDisplayName,
  ) async {
    final state = await _stateFuture;
    if (!mounted) return;
    final candidates = _maps(state['accounts']).where((account) {
      final accountIndex = account['index'] as int? ?? 0;
      return accountIndex != sourceAccountIndex;
    }).toList();
    if (candidates.isEmpty) {
      Get.snackbar(I18n.tip.tr, '没有其他账号可复制'.tr);
      return;
    }

    final selectedIndexes = <int>{};
    final targetIndexes = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('复制$taskDisplayName配置'.tr),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('目标账号没有该任务时会自动添加并启用，再复制账号私有配置；不会复制任务状态和调度时间。'.tr),
                ),
                const SizedBox(height: 8),
                ...candidates.map((account) {
                  final accountIndex = account['index'] as int? ?? 0;
                  return CheckboxListTile(
                    value: selectedIndexes.contains(accountIndex),
                    onChanged: (value) => setDialogState(() {
                      if (value == true) {
                        selectedIndexes.add(accountIndex);
                      } else {
                        selectedIndexes.remove(accountIndex);
                      }
                    }),
                    title: Text(_accountLabel(account)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton.icon(
              onPressed: selectedIndexes.isEmpty
                  ? null
                  : () => Navigator.of(
                      dialogContext,
                    ).pop(selectedIndexes.toList()),
              icon: const Icon(Icons.content_copy_rounded),
              label: Text('复制'.tr),
            ),
          ],
        ),
      ),
    );
    if (targetIndexes == null || targetIndexes.isEmpty) return;
    final success = await ApiClient()
        .copyMultiAccountRepeatTimedTaskPrivateConfig(
          scriptName: widget.scriptName,
          accountIndex: sourceAccountIndex,
          taskName: taskName,
          targetAccountIndexes: targetIndexes,
        );
    if (success) {
      Get.snackbar(I18n.success.tr, '已复制到${targetIndexes.length}个账号'.tr);
      _reload();
    }
  }

  Future<void> _showArgsDialog(ArgsController args, String title) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 720,
          height: 680,
          child: Column(
            children: [
              ListTile(
                title: Text(title),
                trailing: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Expanded(
                child: Args(
                  scriptName: widget.scriptName,
                  taskName: 'MultiAccountRepeatTimed',
                  stagingMode: true,
                  onCancel: () async {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await args.discardDraftChanges();
    _reload();
  }

  Future<String?> _askText(String title, String label) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(I18n.cancel.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(I18n.confirm.tr),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool?> _confirm(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(I18n.cancel.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(I18n.confirm.tr),
          ),
        ],
      ),
    );
  }

  void _bindNativeScheduleRefresh() {
    _nativeScheduleWorker?.dispose();
    _nativeScheduleWorker = bindNativeScheduleRefresh(
      widget.scriptModel,
      _reload,
    );
  }

  void _bindOverviewPush() {
    _overviewWorker = ever(_scriptService.multiAccountOverviewEvents, (_) {
      final event = _scriptService.multiAccountOverviewEvent(
        widget.scriptName,
        'timed',
      );
      if (event == null || !mounted) return;
      final active = event['active'];
      setState(() {
        _activeOverviewTask = active is Map
            ? active.cast<String, dynamic>()
            : null;
      });
      _reload();
    });
  }

  void _watchState(Future<Map<String, dynamic>> future) {
    final generation = ++_stateGeneration;
    future.then(
      (data) {
        if (mounted && generation == _stateGeneration) {
          _liveState.value = data;
        }
      },
      onError: (_, __) {
        if (mounted && generation == _stateGeneration) {
          _liveState.value ??= <String, dynamic>{};
        }
      },
    );
  }

  void _reload() {
    if (!mounted) return;
    final future = ApiClient().getMultiAccountRepeatTimedAccounts(
      scriptName: widget.scriptName,
    );
    _stateFuture = future;
    _watchState(future);
  }
}
