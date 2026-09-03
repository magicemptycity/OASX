import 'package:flutter/material.dart';
import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'package:oasx/modules/home/widgets/task_status_row.dart';
import 'package:oasx/modules/home/widgets/script_schedule_refresh.dart';
import 'package:oasx/modules/home/widgets/task_catalog_row_layout.dart';
import 'package:oasx/modules/home/widgets/task_catalog_panel.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_json_transfer_actions.dart';
import 'package:oasx/modules/home/widgets/shared_public_account_copy_dialog.dart';
import 'package:oasx/modules/home/widgets/account_management_dialogs.dart';
import 'package:oasx/modules/home/widgets/multi_account_enable_tasks_dialog.dart';
import 'package:oasx/translation/i18n_content.dart';

enum _FixedTaskFilter { all, enabled, disabled }

enum _OrchestrationView { overview, tasks }

enum _OrchestrationSettingsPage {
  none,
  public,
  accountTask,
  batchScheduler,
  batchTaskList,
  batchTask,
}

/// 多账号任务编排的独立配置面板。
class MultiAccountTaskOrchestrationPanel extends StatefulWidget {
  const MultiAccountTaskOrchestrationPanel({
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
  State<MultiAccountTaskOrchestrationPanel> createState() =>
      _MultiAccountTaskOrchestrationPanelState();
}

class _MultiAccountTaskOrchestrationPanelState
    extends State<MultiAccountTaskOrchestrationPanel> {
  late Future<Map<String, dynamic>> _stateFuture;
  late final Future<Map<String, List<String>>> _menuFuture;
  final Rxn<Map<String, dynamic>> _liveState = Rxn<Map<String, dynamic>>();
  final ScriptService _scriptService = Get.find<ScriptService>();
  Worker? _overviewWorker;
  Worker? _nativeScheduleWorker;
  Map<String, dynamic>? _activeOverviewTask;
  int _selectedAccount = 1;
  final Set<String> _loadingTasks = <String>{};
  _FixedTaskFilter _specialTaskFilter = _FixedTaskFilter.enabled;
  _OrchestrationView _view = _OrchestrationView.overview;
  int _stateGeneration = 0;
  _OrchestrationSettingsPage _settingsPage = _OrchestrationSettingsPage.none;
  int? _settingsAccountIndex;
  String _settingsTaskName = '';
  String _settingsTaskDisplayName = '';
  String _settingsBatchId = '';
  String _settingsBatchDisplayName = '';
  bool _embeddedBatchShowAllTasks = false;
  int _embeddedBatchTaskListGeneration = 0;
  _OrchestrationSettingsPage? _returnToBatchPage;

  @override
  void initState() {
    super.initState();
    _stateFuture = ApiClient().getMultiAccountTaskOrchestrationAccounts(
      scriptName: widget.scriptName,
    );
    _watchState(_stateFuture);
    _menuFuture = ApiClient().getScriptMenu();
    _bindOverviewPush();
    _bindNativeScheduleRefresh();
  }

  @override
  void dispose() {
    _overviewWorker?.dispose();
    _nativeScheduleWorker?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MultiAccountTaskOrchestrationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptName == widget.scriptName) {
      return;
    }
    _selectedAccount = 1;
    _settingsPage = _OrchestrationSettingsPage.none;
    _settingsAccountIndex = null;
    _settingsTaskName = '';
    _settingsTaskDisplayName = '';
    _settingsBatchId = '';
    _settingsBatchDisplayName = '';
    _returnToBatchPage = null;
    _bindNativeScheduleRefresh();
    _activeOverviewTask = null;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_settingsPage != _OrchestrationSettingsPage.none) {
      return _buildSettingsPage(context);
    }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, accounts),
        const SizedBox(height: 12),
        Expanded(
          // 与“多账号多任务定时”直接使用相同的任务容器颜色与 Card 参数。
          child: Card(
            color: Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: 0.24),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('总览'.tr),
                        selected: _view == _OrchestrationView.overview,
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _view = _OrchestrationView.overview),
                      ),
                      ChoiceChip(
                        label: Text('任务'.tr),
                        selected: _view == _OrchestrationView.tasks,
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _view = _OrchestrationView.tasks),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _view == _OrchestrationView.overview
                        ? _buildNativeOverview(account)
                        : _buildAccountContent(context, account),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskToolbar(BuildContext context) {
    final canQuickSchedule =
        widget.controller.isTaskEnabled(
          widget.scriptModel,
          'MultiAccountTaskOrchestration',
        ) &&
        widget.controller.canQuickScheduleTask(
          widget.scriptModel,
          'MultiAccountTaskOrchestration',
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
            '多账号任务编排'.tr,
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
          taskName: 'MultiAccountTaskOrchestration',
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
      taskName: 'MultiAccountTaskOrchestration',
      runNow: runNow,
    );
    if (success) {
      Get.snackbar(I18n.success.tr, '多账号任务编排'.tr);
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
                  onPressed: _openPublicSettings,
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

  Widget _buildNativeOverview(Map<String, dynamic> account) {
    final accountIndex = account['index'] as int? ?? _selectedAccount;
    final items =
        _filteredOverviewItems([
          ..._maps(account['fixed_time_batches']),
          ..._maps(account['single_tasks']),
        ])..sort((left, right) {
          final leftDue = left['due'] == true;
          final rightDue = right['due'] == true;
          if (leftDue != rightDue) return leftDue ? -1 : 1;
          final leftTime =
              DateTime.tryParse('${left['next_run'] ?? ''}') ?? DateTime(9999);
          final rightTime =
              DateTime.tryParse('${right['next_run'] ?? ''}') ?? DateTime(9999);
          final byTime = leftTime.compareTo(rightTime);
          if (byTime != 0) return byTime;
          return (left['priority'] as int? ?? 5).compareTo(
            right['priority'] as int? ?? 5,
          );
        });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_accountLabel(account)}：编排任务',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            PopupMenuButton<_FixedTaskFilter>(
              tooltip: _fixedTaskFilterLabel(_specialTaskFilter),
              initialValue: _specialTaskFilter,
              onSelected: (value) => setState(() => _specialTaskFilter = value),
              itemBuilder: (context) => _FixedTaskFilter.values
                  .map(
                    (value) => PopupMenuItem<_FixedTaskFilter>(
                      value: value,
                      child: Text(_fixedTaskFilterLabel(value)),
                    ),
                  )
                  .toList(),
              icon: Icon(
                Icons.filter_list_rounded,
                color: _specialTaskFilter == _FixedTaskFilter.all
                    ? null
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            IconButton(
              tooltip: '删除账号'.tr,
              onPressed: () => _deleteTaskAccount(accountIndex),
              icon: const Icon(Icons.person_remove_outlined),
            ),
            FilledButton.icon(
              onPressed: () => _addFixedTimeBatch(accountIndex),
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              label: const Text('添加顺序任务组'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _showAddTaskDialog(accountIndex),
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: Text('启用任务'.tr),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '顺序任务组与独立单任务均在此管理；筛选可查看全部、已启用或未启用任务。'.tr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    _specialTaskFilter == _FixedTaskFilter.all
                        ? '当前账号还没有编排项。'.tr
                        : '当前筛选条件下没有编排任务。'.tr,
                  ),
                )
              : ListView.separated(
                  key: PageStorageKey<String>(
                    'orchestration-overview-$accountIndex',
                  ),
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildNativeOverviewRow(accountIndex, items[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildNativeOverviewRow(int accountIndex, Map<String, dynamic> item) {
    // 顺序任务组不是普通单任务：必须保留其任务状态、调度器、任务列表、
    // 复制和删除等完整操作，不能用通用 TaskStatusRow 把它们裁掉。
    if (item['item_type'] != 'single') {
      return _buildFixedTimeBatchItem(context, accountIndex, item);
    }
    final isSingle = item['item_type'] == 'single';
    final identifier = isSingle
        ? '${item['task_name'] ?? ''}'.trim()
        : '${item['batch_id'] ?? ''}'.trim();
    final enabled = item['enable'] == true;
    final due = item['due'] == true;
    final nextRun = '${item['next_run'] ?? ''}'.trim();
    final isRunning =
        _activeOverviewTask?['account_index'] == accountIndex &&
        (isSingle
            ? '${_activeOverviewTask?['task_name'] ?? ''}' == identifier
            : '${_activeOverviewTask?['batch_id'] ?? ''}' == identifier);
    final type = isRunning
        ? TaskStatusType.running
        : due
        ? TaskStatusType.pending
        : TaskStatusType.waiting;
    final view = TaskStatusViewData(
      rowId:
          'orchestration:${isSingle ? 'single' : 'group'}:$accountIndex:$identifier:$nextRun',
      name: identifier,
      displayName: '${item['name'] ?? identifier}',
      type: type,
      timeText: nextRun,
    );
    return TaskStatusRow(
      key: ValueKey(view.rowId),
      controller: widget.controller,
      sourceScriptName: widget.scriptName,
      task: view,
      canQuickSchedule: enabled && !isRunning,
      quickScheduleLocked: isRunning,
      leadingActions: isSingle
          ? const []
          : [
              TaskStatusActionIcon(
                icon: Icons.list_alt_rounded,
                tooltip: '任务列表'.tr,
                onPressed: () =>
                    _openFixedTimeBatchTaskList(accountIndex, item),
              ),
            ],
      onSetNextRun: (_, value) => isSingle
          ? _setSingleTaskNextRun(accountIndex, identifier, value)
          : _setGroupNextRun(accountIndex, identifier, value),
      onQuickRun: (_) => isSingle
          ? _quickScheduleSingleTask(accountIndex, identifier, runNow: true)
          : _quickScheduleSpecialTask(accountIndex, identifier, runNow: true),
      onQuickWait: (_) => isSingle
          ? _quickScheduleSingleTask(accountIndex, identifier, runNow: false)
          : _quickScheduleSpecialTask(accountIndex, identifier, runNow: false),
      onEditTask: (_) => isSingle
          ? _openTaskSettings(
              accountIndex,
              identifier,
              '${item['name'] ?? identifier}',
            )
          : _openFixedTimeBatchSchedulerSettings(accountIndex, item),
      onDisableTask: (_) => isSingle
          ? _setSingleTaskEnabled(accountIndex, identifier, false)
          : _disableFixedSpecialTask(accountIndex, identifier),
      onDismissed: (_) => _reload(),
      dragEnabled: false,
      swipeEnabled: enabled && !isRunning,
      activeDragPayload: null,
    );
  }

  Future<void> _setSingleTaskNextRun(
    int accountIndex,
    String taskName,
    String value,
  ) async {
    if (await ApiClient().putMultiAccountTaskOrchestrationTaskArg(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
      groupName: 'scheduler',
      argumentName: 'next_run',
      type: 'date_time',
      value: value,
    )) {
      _reload();
    }
  }

  Future<bool> _setSingleTaskEnabled(
    int accountIndex,
    String taskName,
    bool value,
  ) async {
    final ok = await ApiClient().putMultiAccountTaskOrchestrationTaskArg(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
      groupName: 'scheduler',
      argumentName: 'enable',
      type: 'boolean',
      value: value,
    );
    if (ok) _reload();
    return ok;
  }

  Future<void> _setGroupNextRun(
    int accountIndex,
    String batchId,
    String value,
  ) async {
    if (await ApiClient()
        .putMultiAccountTaskOrchestrationFixedTimeBatchSchedulerArg(
          scriptName: widget.scriptName,
          accountIndex: accountIndex,
          batchId: batchId,
          argumentName: 'next_run',
          type: 'date_time',
          value: value,
        )) {
      _reload();
    }
  }

  Widget _buildAccountContent(
    BuildContext context,
    Map<String, dynamic> account,
  ) {
    final accountIndex = account['index'] as int? ?? _selectedAccount;
    final enabledKeys = <String>{
      for (final item in _maps(
        account['single_tasks'],
      ).where((item) => item['enable'] == true))
        _fixedTaskKey('${item['task_name'] ?? ''}'),
    };
    return TaskCatalogPanel(
      key: ValueKey<String>(
        'orchestration-native-catalog-$accountIndex-$_stateGeneration',
      ),
      embedded: true,
      catalogGeneration: _stateGeneration,
      controller: widget.controller,
      scriptModel: widget.scriptModel,
      isTaskEnabledOverride: (taskName) =>
          enabledKeys.contains(_fixedTaskKey(taskName)),
      onToggleEnabledOverride: (taskName, enable) => enable
          ? ApiClient().addMultiAccountTaskOrchestrationSingleTask(
              scriptName: widget.scriptName,
              accountIndex: accountIndex,
              taskName: taskName,
            )
          : _setSingleTaskEnabled(accountIndex, taskName, false),
      canQuickScheduleOverride: (taskName) =>
          enabledKeys.contains(_fixedTaskKey(taskName)),
      onOpenTask: (taskName) =>
          _openTaskSettings(accountIndex, taskName, taskName.tr),
      onQuickRun: (taskName) =>
          _quickScheduleSingleTask(accountIndex, taskName, runNow: true),
      onQuickWait: (taskName) =>
          _quickScheduleSingleTask(accountIndex, taskName, runNow: false),
    );
  }

  List<Map<String, dynamic>> _filteredOverviewItems(
    List<Map<String, dynamic>> items,
  ) {
    return items.where((item) {
      final isGroup = item['item_type'] != 'single';
      final enabled = item['enable'] == true;
      return switch (_specialTaskFilter) {
        _FixedTaskFilter.enabled => enabled,
        _FixedTaskFilter.disabled => isGroup && !enabled,
        _FixedTaskFilter.all => enabled || isGroup,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _filteredSpecialTasks(
    List<Map<String, dynamic>> batches,
  ) {
    return batches.where((batch) {
      final enabled = batch['enable'] == true;
      return switch (_specialTaskFilter) {
        _FixedTaskFilter.all => true,
        _FixedTaskFilter.enabled => enabled,
        _FixedTaskFilter.disabled => !enabled,
      };
    }).toList();
  }

  Widget _buildNativeTaskCatalog(
    int accountIndex,
    Map<String, dynamic> account,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        ApiClient().getScriptMenu(),
        ApiClient().getMultiAccountTaskOrchestrationFixedTimeTasks(
          scriptName: widget.scriptName,
        ),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final menu =
            snapshot.data?[0] as Map<String, List<String>>? ?? const {};
        final catalog =
            snapshot.data?[1] as List<Map<String, dynamic>>? ?? const [];
        final byKey = <String, Map<String, dynamic>>{
          for (final item in catalog)
            _fixedTaskKey('${item['task_name'] ?? ''}'): item,
        };
        final enabled = <String>{
          for (final item in _maps(
            account['single_tasks'],
          ).where((item) => item['enable'] == true))
            _fixedTaskKey('${item['task_name'] ?? ''}'),
        };
        final sections = menu.entries
            .map(
              (entry) => MapEntry(
                entry.key,
                entry.value
                    .map((name) => byKey[_fixedTaskKey(name)])
                    .whereType<Map<String, dynamic>>()
                    .toList(),
              ),
            )
            .where((entry) => entry.value.isNotEmpty)
            .toList();
        if (sections.isEmpty) return Text('没有可启用的任务。'.tr);
        return ExpansionTileGroup(
          spaceBetweenItem: 10,
          children: sections.map((section) {
            return ExpansionTileItem(
              key: ValueKey<String>(
                'orchestration-task-category-${section.key}',
              ),
              initiallyExpanded: false,
              isHasTopBorder: false,
              isHasBottomBorder: false,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.24),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              title: Row(
                children: [
                  const Icon(Icons.drag_indicator_rounded),
                  const SizedBox(width: 10),
                  Expanded(child: Text(section.key.tr)),
                  Text('${section.value.length}'),
                ],
              ),
              children: [
                const Divider(),
                for (final item in section.value)
                  _buildNativeCatalogTaskRow(accountIndex, item, enabled),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNativeCatalogTaskRow(
    int accountIndex,
    Map<String, dynamic> task,
    Set<String> enabled,
  ) {
    final taskName = '${task['task_name'] ?? ''}'.trim();
    final taskKey = _fixedTaskKey(taskName);
    final isEnabled = enabled.contains(taskKey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TaskCatalogSplitRow(
        scrollKey: PageStorageKey<String>(
          'orchestration-catalog-$accountIndex-$taskName',
        ),
        taskLabel: Text('${task['task_display_name'] ?? taskName}'.tr),
        supportsEnable: true,
        enabled: isEnabled,
        loading: _loadingTasks.contains('catalog:$taskName'),
        onToggleEnabled: (value) =>
            _toggleSingleCatalogTask(accountIndex, taskName, value),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskCatalogIconOnlyButton(
              icon: Icons.tune_rounded,
              tooltip: I18n.homeOpenTaskParams.tr,
              // 未启用任务也可以先保存私有配置；首次保存由后端创建停用项。
              onPressed: () => _openTaskSettings(
                accountIndex,
                taskName,
                '${task['task_display_name'] ?? taskName}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSingleCatalogTask(
    int accountIndex,
    String taskName,
    bool enable,
  ) async {
    final key = 'catalog:$taskName';
    if (_loadingTasks.contains(key)) return;
    setState(() => _loadingTasks.add(key));
    final ok = enable
        ? await ApiClient().addMultiAccountTaskOrchestrationSingleTask(
            scriptName: widget.scriptName,
            accountIndex: accountIndex,
            taskName: taskName,
          )
        : await _setSingleTaskEnabled(accountIndex, taskName, false);
    if (!mounted) return;
    setState(() => _loadingTasks.remove(key));
    if (ok) _reload();
  }

  // 保留旧卡片实现供后续移除前兼容；页面不再调用。
  // ignore: unused_element
  Widget _buildFixedTimeBatches(
    BuildContext context,
    Map<String, dynamic> account,
  ) {
    final accountIndex = account['index'] as int? ?? _selectedAccount;
    // 后端已按 OAS 总览队列顺序返回：待执行优先，等待任务按 NextRun 升序。
    final batches =
        _filteredSpecialTasks([
          ..._maps(account['fixed_time_batches']),
          ..._maps(account['single_tasks']),
        ])..sort((left, right) {
          final leftDue = left['due'] == true;
          final rightDue = right['due'] == true;
          if (leftDue != rightDue) return leftDue ? -1 : 1;
          final leftTime =
              DateTime.tryParse('${left['next_run'] ?? ''}') ?? DateTime(9999);
          final rightTime =
              DateTime.tryParse('${right['next_run'] ?? ''}') ?? DateTime(9999);
          final byTime = leftTime.compareTo(rightTime);
          if (byTime != 0) return byTime;
          return (left['priority'] as int? ?? 5).compareTo(
            right['priority'] as int? ?? 5,
          );
        });
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
                    '${_accountLabel(account)}：编排任务',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<_FixedTaskFilter>(
                  tooltip: _fixedTaskFilterLabel(_specialTaskFilter),
                  initialValue: _specialTaskFilter,
                  onSelected: (value) =>
                      setState(() => _specialTaskFilter = value),
                  itemBuilder: (context) => _FixedTaskFilter.values
                      .map(
                        (value) => PopupMenuItem<_FixedTaskFilter>(
                          value: value,
                          child: Text(_fixedTaskFilterLabel(value)),
                        ),
                      )
                      .toList(),
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: _specialTaskFilter == _FixedTaskFilter.all
                        ? null
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  tooltip: '删除账号'.tr,
                  onPressed: () => _deleteTaskAccount(accountIndex),
                  icon: const Icon(Icons.person_remove_outlined),
                ),
                FilledButton.icon(
                  onPressed: () => _addFixedTimeBatch(accountIndex),
                  icon: const Icon(Icons.account_tree_outlined, size: 18),
                  label: const Text('添加顺序任务组'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showAddTaskDialog(accountIndex),
                  icon: const Icon(Icons.playlist_add_rounded, size: 18),
                  label: Text('启用任务'.tr),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '每个顺序任务组都是当前账号的一次独立运行：拥有原生 OAS 调度器、独立状态和按顺序执行的任务列表。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (batches.isEmpty)
              Text(
                _specialTaskFilter == _FixedTaskFilter.all
                    ? '当前账号还没有顺序任务组。'.tr
                    : '当前筛选条件下没有顺序任务组。'.tr,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...batches.map(
                (batch) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: batch['item_type'] == 'single'
                      ? _buildSingleTaskItem(context, accountIndex, batch)
                      : _buildFixedTimeBatchItem(context, accountIndex, batch),
                ),
              ),
            const Divider(height: 24),
            Text('任务分类'.tr, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildNativeTaskCatalog(accountIndex, account),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleTaskItem(
    BuildContext context,
    int accountIndex,
    Map<String, dynamic> task,
  ) {
    final taskName = '${task['task_name'] ?? ''}'.trim();
    final enabled = task['enable'] == true;
    final due = task['due'] == true;
    final nextRun = '${task['next_run'] ?? ''}'.trim();
    final status =
        '${task['task_progress'] is Map ? task['task_progress']['status'] : 'pending'}';
    final overviewType = due ? TaskStatusType.pending : TaskStatusType.waiting;
    return TaskOverviewCard(
      key: ValueKey<String>('orchestration-single:$taskName:$enabled'),
      type: enabled ? overviewType : TaskStatusType.waiting,
      swipeEnabled: false,
      child: Row(
        children: [
          Tooltip(
            message: enabled ? (due ? '待执行'.tr : '等待执行'.tr) : '未启用'.tr,
            child: TaskStatusTypeIcon(
              type: enabled ? overviewType : TaskStatusType.waiting,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task['name'] ?? taskName}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  nextRun.isEmpty
                      ? '尚未安排下次运行'.tr
                      : (due ? '待执行：$nextRun' : '下次运行：$nextRun'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '独立单任务 · ${_taskStatusLabel(status)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: I18n.homeQuickRun.tr,
            onPressed: !enabled || taskName.isEmpty
                ? null
                : () => _quickScheduleSingleTask(
                    accountIndex,
                    taskName,
                    runNow: true,
                  ),
            icon: const Icon(Icons.flash_on_rounded),
          ),
          IconButton(
            tooltip: I18n.homeQuickWait.tr,
            onPressed: !enabled || taskName.isEmpty
                ? null
                : () => _quickScheduleSingleTask(
                    accountIndex,
                    taskName,
                    runNow: false,
                  ),
            icon: const Icon(Icons.schedule_rounded),
          ),
          IconButton(
            tooltip: '任务与调度器设置'.tr,
            onPressed: taskName.isEmpty
                ? null
                : () => _openTaskSettings(
                    accountIndex,
                    taskName,
                    '${task['name'] ?? taskName}',
                  ),
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: '删除独立单任务'.tr,
            onPressed: taskName.isEmpty
                ? null
                : () => _deleteTask(accountIndex, taskName),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _quickScheduleSingleTask(
    int accountIndex,
    String taskName, {
    required bool runNow,
  }) async {
    if (await ApiClient().quickScheduleMultiAccountTaskOrchestrationSingleTask(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
      runNow: runNow,
    )) {
      _reload();
    }
  }

  Widget _buildFixedTimeBatchItem(
    BuildContext context,
    int accountIndex,
    Map<String, dynamic> batch,
  ) {
    final batchId = '${batch['batch_id'] ?? ''}';
    final enabled = batch['enable'] == true;
    final tasks = _maps(batch['tasks']);
    final nextRun = '${batch['next_run'] ?? ''}'.trim();
    final due = batch['due'] == true;
    final canEdit = batchId.isNotEmpty;
    final nextRunLabel = nextRun.isEmpty
        ? '尚未安排下次运行'
        : due
        ? '待执行：$nextRun'
        : '下次运行：$nextRun';
    final activeAccountIndex = _activeOverviewTask?['account_index'];
    final activeBatchId = '${_activeOverviewTask?['batch_id'] ?? ''}';
    final isRunning =
        activeAccountIndex == accountIndex && activeBatchId == batchId;
    final scheduleStatus = isRunning
        ? 'running'
        : '${batch['schedule_status'] ?? ''}';
    final overviewType = switch (scheduleStatus) {
      'running' => TaskStatusType.running,
      'pending' => TaskStatusType.pending,
      _ => TaskStatusType.waiting,
    };
    return TaskOverviewCard(
      key: ValueKey<String>('fixed-special-task:$batchId:$enabled'),
      type: enabled ? overviewType : TaskStatusType.waiting,
      // 与 OAS 总览任务一致：向左滑动停用当前顺序任务组。
      swipeEnabled: canEdit && enabled && !isRunning,
      onConfirmDismiss: () => _disableFixedSpecialTask(accountIndex, batchId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 操作顺序：调度器、任务列表、复制、删除。
          Row(
            children: [
              Tooltip(
                message: enabled
                    ? (isRunning
                          ? '正在运行'.tr
                          : due
                          ? '待执行'.tr
                          : '等待执行'.tr)
                    : '未启用'.tr,
                child: TaskStatusTypeIcon(
                  type: enabled ? overviewType : TaskStatusType.waiting,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${batch['name'] ?? '未命名顺序任务组'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      nextRunLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      _batchScheduleLabel(batch),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '账号任务状态与重新执行'.tr,
                onPressed: !canEdit
                    ? null
                    : () => _showSpecialTaskStatusDialog(accountIndex, batch),
                icon: const Icon(Icons.fact_check_outlined),
              ),
              IconButton(
                tooltip: I18n.homeQuickRun.tr,
                onPressed: !canEdit || !enabled || isRunning
                    ? null
                    : () => _quickScheduleSpecialTask(
                        accountIndex,
                        batchId,
                        runNow: true,
                      ),
                icon: const Icon(Icons.flash_on_rounded),
              ),
              IconButton(
                tooltip: I18n.homeQuickWait.tr,
                onPressed: !canEdit || !enabled || isRunning
                    ? null
                    : () => _quickScheduleSpecialTask(
                        accountIndex,
                        batchId,
                        runNow: false,
                      ),
                icon: const Icon(Icons.schedule_rounded),
              ),
              IconButton(
                tooltip: '调度器设置'.tr,
                onPressed: !canEdit
                    ? null
                    : () => _openFixedTimeBatchSchedulerSettings(
                        accountIndex,
                        batch,
                      ),
                icon: const Icon(Icons.tune_rounded),
              ),
              IconButton(
                tooltip: '${'任务列表'.tr}（${tasks.length}）',
                onPressed: !canEdit
                    ? null
                    : () => _openFixedTimeBatchTaskList(accountIndex, batch),
                icon: const Icon(Icons.list_alt_rounded),
              ),
              IconButton(
                tooltip: '复制顺序任务组到其他账号'.tr,
                onPressed: !canEdit
                    ? null
                    : () =>
                          _showCopyFixedTimeBatchDialog(accountIndex, batchId),
                icon: const Icon(Icons.content_copy_rounded),
              ),
              IconButton(
                tooltip: '删除顺序任务组',
                onPressed: !canEdit
                    ? null
                    : () => _deleteFixedTimeBatch(accountIndex, batchId),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCopyFixedTimeBatchDialog(
    int sourceAccountIndex,
    String batchId,
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

    var keyword = '';
    final selectedIndexes = <int>{};
    final targetIndexes = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final query = keyword.trim().toLowerCase();
          final visibleAccounts = candidates.where((account) {
            final searchText =
                '${_accountLabel(account)} ${_accountPickerDetail(account)}'
                    .toLowerCase();
            return query.isEmpty || searchText.contains(query);
          }).toList();
          return AlertDialog(
            title: const Text('复制顺序任务组'),
            content: SizedBox(
              width: 460,
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('将复制时间、周期、启用状态、任务及私有配置；不会复制任务状态、运行记录和上次成功时间。'),
                  const SizedBox(height: 10),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: '搜索账号、角色名或服务器'.tr,
                    ),
                    onChanged: (value) => setDialogState(() => keyword = value),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: visibleAccounts.isEmpty
                        ? const Center(child: Text('没有匹配的账号'))
                        : ListView.builder(
                            itemCount: visibleAccounts.length,
                            itemBuilder: (context, index) {
                              final account = visibleAccounts[index];
                              final accountIndex =
                                  account['index'] as int? ?? 0;
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
                                subtitle: Text(_accountPickerDetail(account)),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
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
          );
        },
      ),
    );
    if (targetIndexes == null || targetIndexes.isEmpty) return;
    final success = await ApiClient()
        .copyMultiAccountTaskOrchestrationFixedTimeBatch(
          scriptName: widget.scriptName,
          accountIndex: sourceAccountIndex,
          batchId: batchId,
          targetAccountIndexes: targetIndexes,
        );
    if (success) {
      Get.snackbar(I18n.success.tr, '已复制到${targetIndexes.length}个账号'.tr);
      _reload();
    }
  }

  // ignore: unused_element
  Widget _buildTaskList(BuildContext context, Map<String, dynamic> account) {
    final tasks = _maps(account['tasks']);
    final accountIndex = account['index'] as int? ?? _selectedAccount;
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
                    '${_accountLabel(account)}：普通任务列表',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '删除账号'.tr,
                  onPressed: () => _deleteTaskAccount(accountIndex),
                  icon: const Icon(Icons.person_remove_outlined),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddTaskDialog(accountIndex),
                  icon: const Icon(Icons.add_rounded),
                  label: Text('添加任务'.tr),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              Expanded(child: Center(child: Text('当前账号尚未添加任务'.tr)))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final taskName = '${task['task_name'] ?? ''}'.trim();
                    final taskDisplayName =
                        '${task['task_display_name'] ?? taskName}'.trim();
                    final status = '${task['status'] ?? 'pending'}';
                    final loading = _loadingTasks.contains(taskName);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _taskStatusIcon(status),
                        color: _taskStatusColor(context, status),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(taskDisplayName)),
                          const SizedBox(width: 8),
                          _buildTaskStatusBadge(context, status),
                        ],
                      ),
                      subtitle: Text(_taskStatusLabel(status)),
                      trailing: Wrap(
                        spacing: 2,
                        children: [
                          IconButton(
                            tooltip: '设置私有配置'.tr,
                            onPressed: loading || taskName.isEmpty
                                ? null
                                : () => _openTaskSettings(
                                    accountIndex,
                                    taskName,
                                    taskDisplayName,
                                  ),
                            icon: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.settings_rounded),
                          ),
                          IconButton(
                            tooltip: '删除任务'.tr,
                            onPressed: loading || taskName.isEmpty
                                ? null
                                : () => _deleteTask(accountIndex, taskName),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _taskStatusIcon(String status) {
    return switch (status) {
      'completed' => Icons.check_circle_rounded,
      'failed' => Icons.error_rounded,
      'unfinished' => Icons.pause_circle_rounded,
      _ => Icons.radio_button_unchecked_rounded,
    };
  }

  Color? _taskStatusColor(BuildContext context, String status) {
    return switch (status) {
      'completed' => Colors.green,
      'failed' => Theme.of(context).colorScheme.error,
      'unfinished' => Colors.orange,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  String _taskStatusLabel(String status) {
    return switch (status) {
      'completed' => '今日已完成',
      'failed' => '今日运行失败',
      'unfinished' => '今日未完成',
      _ => '今日待运行',
    };
  }

  Widget _buildTaskStatusBadge(BuildContext context, String status) {
    final color =
        _taskStatusColor(context, status) ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: _taskStatusLabel(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _taskStatusLabel(status),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
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
            setState(() => _selectedAccount = selected);
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
        (await ApiClient().getMultiAccountTaskOrchestrationPublicAccounts(
          scriptName: widget.scriptName,
        ))['accounts'],
      ),
      onDelete: (identifier) =>
          ApiClient().deleteMultiAccountTaskOrchestrationPublicAccount(
            scriptName: widget.scriptName,
            identifier: identifier,
          ),
      onEdit: _editPublicAccount,
      onAdd: () async {
        final identifier = await _askText('新增公共账号'.tr, '账号标识'.tr);
        if (identifier == null || identifier.trim().isEmpty) return false;
        return ApiClient().addMultiAccountTaskOrchestrationPublicAccount(
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
                      .putMultiAccountTaskOrchestrationPublicAccountValue(
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
    final library = await ApiClient()
        .getMultiAccountTaskOrchestrationPublicAccounts(
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
      await ApiClient().addMultiAccountTaskOrchestrationAccount(
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
      await ApiClient().deleteMultiAccountTaskOrchestrationAccount(
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
    if (await ApiClient().deleteMultiAccountTaskOrchestrationAccount(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
    )) {
      _selectedAccount = 1;
      _reload();
    }
  }

  Future<void> _addFixedTimeBatch(int accountIndex) async {
    final name = await _askText('创建顺序任务组'.tr, '任务组名称'.tr);
    if (name == null) return;
    // 顺序任务组创建后，通过原生 OAS 调度器决定是否启用及下次运行时间。
    if (await ApiClient().addMultiAccountTaskOrchestrationFixedTimeBatch(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      name: name.trim(),
    )) {
      _reload();
    }
  }

  Future<void> _quickScheduleSpecialTask(
    int accountIndex,
    String batchId, {
    required bool runNow,
  }) async {
    final ok = await ApiClient()
        .quickScheduleMultiAccountTaskOrchestrationSpecialTask(
          scriptName: widget.scriptName,
          accountIndex: accountIndex,
          batchId: batchId,
          runNow: runNow,
        );
    if (ok) _reload();
  }

  Future<void> _rerunSpecialTask(int accountIndex, String batchId) async {
    if (await ApiClient().rerunMultiAccountTaskOrchestrationSpecialTask(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      batchId: batchId,
    )) {
      _reload();
    }
  }

  Future<void> _showSpecialTaskStatusDialog(
    int accountIndex,
    Map<String, dynamic> batch,
  ) async {
    final batchId = '${batch['batch_id'] ?? ''}';
    if (batchId.isEmpty) return;
    final progress = batch['task_progress'] is Map
        ? (batch['task_progress'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${batch['name'] ?? '未命名顺序任务组'}：账号任务状态'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_calendar_outlined),
                title: Text('修改上次完整完成时间'.tr),
                subtitle: Text('使用与调度器相同的时间选择器'.tr),
                trailing: DateTimePicker(
                  value:
                      '${batch['last_complete_time'] ?? '2023-01-01 00:00:00'}',
                  minDate: DateTime(2023, 1, 1),
                  maxDate: DateTime(2100, 12, 31, 23, 59, 59),
                  notHoverStyle: Theme.of(context).textTheme.labelLarge,
                  hoverStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onChange: (value) async {
                    final ok = await ApiClient()
                        .setMultiAccountTaskOrchestrationSpecialTaskLastCompleteTime(
                          scriptName: widget.scriptName,
                          accountIndex: accountIndex,
                          batchId: batchId,
                          value: value,
                        );
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      _reload();
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text('已完成：${progress['completed_task_list'] ?? '-'}'),
              Text('失败：${progress['failed_task_list'] ?? '-'}'),
              Text('未完成：${progress['unfinished_task_list'] ?? '-'}'),
              const SizedBox(height: 10),
              Text('状态仅属于当前顺序任务组，不会影响同账号其他任务组。'.tr),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('关闭'.tr),
          ),
          FilledButton.icon(
            onPressed: () async {
              await _rerunSpecialTask(accountIndex, batchId);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            icon: const Icon(Icons.replay_rounded),
            label: Text('重新执行'.tr),
          ),
        ],
      ),
    );
  }

  String _batchScheduleLabel(Map<String, dynamic> batch) {
    if (batch['enable'] != true) return '调度器未启用'.tr;
    final runTime = '${batch['run_time'] ?? '--:--'}';
    final mode = '${batch['schedule_mode'] ?? 'interval_days'}';
    if (mode == 'weekday') {
      final weekdays = (batch['weekdays'] as List? ?? const [])
          .map((value) => int.tryParse('$value'))
          .whereType<int>()
          .toList();
      return '${_weekdaysLabel(weekdays)} · $runTime';
    }
    final interval = batch['interval_days'] as int? ?? 1;
    return interval <= 1 ? '每天 · $runTime' : '每隔$interval天 · $runTime';
  }

  String _weekdaysLabel(Iterable<int> weekdays) {
    const labels = {
      1: '周一',
      2: '周二',
      3: '周三',
      4: '周四',
      5: '周五',
      6: '周六',
      7: '周日',
    };
    final values = weekdays.where(labels.containsKey).toList()..sort();
    return values.isEmpty
        ? '未选择星期'
        : values.map((day) => labels[day]).join('、');
  }

  Future<void> _openFixedTimeBatchSchedulerSettings(
    int accountIndex,
    Map<String, dynamic> batch,
  ) async {
    final batchId = '${batch['batch_id'] ?? ''}'.trim();
    if (batchId.isEmpty) return;
    final data = await ApiClient()
        .getMultiAccountTaskOrchestrationFixedTimeBatchSchedulerArgs(
          scriptName: widget.scriptName,
          accountIndex: accountIndex,
          batchId: batchId,
        );
    if (!mounted || data.isEmpty) return;
    final args = Get.find<ArgsController>();
    await args.loadGroupsFromData(
      config: widget.scriptName,
      task: 'MultiAccountTaskOrchestration',
      json: data,
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) {
        return ApiClient()
            .putMultiAccountTaskOrchestrationFixedTimeBatchSchedulerArg(
              scriptName: config,
              accountIndex: accountIndex,
              batchId: batchId,
              argumentName: argument,
              type: type,
              value: value,
            );
      },
    );
    if (!mounted) return;
    setState(() {
      _settingsPage = _OrchestrationSettingsPage.batchScheduler;
      _settingsAccountIndex = accountIndex;
      _settingsTaskName = '';
      _settingsTaskDisplayName = '';
      _settingsBatchId = batchId;
      _settingsBatchDisplayName =
          '${batch['name'] ?? batch['run_time'] ?? '--:--'}';
      _returnToBatchPage = null;
    });
  }

  void _openFixedTimeBatchTaskList(
    int accountIndex,
    Map<String, dynamic> batch,
  ) {
    final batchId = '${batch['batch_id'] ?? ''}'.trim();
    if (batchId.isEmpty) return;
    setState(() {
      _settingsPage = _OrchestrationSettingsPage.batchTaskList;
      _settingsAccountIndex = accountIndex;
      _settingsTaskName = '';
      _settingsTaskDisplayName = '';
      _settingsBatchId = batchId;
      _settingsBatchDisplayName =
          '${batch['name'] ?? batch['run_time'] ?? '--:--'}';
      _embeddedBatchShowAllTasks = false;
      _embeddedBatchTaskListGeneration++;
      _returnToBatchPage = null;
    });
  }

  Future<bool> _disableFixedSpecialTask(
    int accountIndex,
    String batchId,
  ) async {
    final ok = await ApiClient()
        .setMultiAccountTaskOrchestrationFixedTimeBatchEnable(
          scriptName: widget.scriptName,
          accountIndex: accountIndex,
          batchId: batchId,
          enable: false,
        );
    if (ok) _reload();
    return ok;
  }

  Future<void> _deleteFixedTimeBatch(int accountIndex, String batchId) async {
    final confirmed = await _confirm(
      '删除顺序任务组',
      '删除后会一并删除该顺序任务组内的任务、私有配置和运行记录，是否继续？',
    );
    if (confirmed != true) return;
    if (await ApiClient().deleteMultiAccountTaskOrchestrationFixedTimeBatch(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      batchId: batchId,
    )) {
      _reload();
    }
  }

  Widget _buildEmbeddedBatchTaskList(
    BuildContext context,
    int accountIndex,
    String batchId,
    String batchDisplayName, {
    required double listHeight,
  }) {
    final account = _maps(_liveState.value?['accounts']).firstWhere(
      (item) => item['index'] == accountIndex,
      orElse: () => <String, dynamic>{},
    );
    final batch = _maps(account['fixed_time_batches']).firstWhere(
      (item) => item['batch_id'] == batchId,
      orElse: () => <String, dynamic>{},
    );
    final tasks = _maps(batch['tasks']);
    final enabledTasks = tasks
        .where((task) => task['enable'] != false)
        .toList();
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.24),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$batchDisplayName：${'任务列表'.tr}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.list_alt_rounded),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('总览'.tr),
                  selected: !_embeddedBatchShowAllTasks,
                  showCheckmark: false,
                  onSelected: (_) =>
                      setState(() => _embeddedBatchShowAllTasks = false),
                ),
                ChoiceChip(
                  label: Text('任务'.tr),
                  selected: _embeddedBatchShowAllTasks,
                  showCheckmark: false,
                  onSelected: (_) =>
                      setState(() => _embeddedBatchShowAllTasks = true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: listHeight,
              child: _embeddedBatchShowAllTasks
                  ? TaskCatalogPanel(
                      key: ValueKey<String>(
                        'orchestration-batch-catalog-$accountIndex-$batchId-$_embeddedBatchTaskListGeneration',
                      ),
                      embedded: true,
                      controller: widget.controller,
                      scriptModel: widget.scriptModel,
                      catalogGeneration: _embeddedBatchTaskListGeneration,
                      isTaskEnabledOverride: (taskName) => tasks.any(
                        (task) =>
                            _fixedTaskKey('${task['task_name'] ?? ''}') ==
                                _fixedTaskKey(taskName) &&
                            task['enable'] != false,
                      ),
                      onToggleEnabledOverride: (taskName, enable) =>
                          _toggleEmbeddedBatchTask(
                            accountIndex,
                            batchId,
                            tasks,
                            taskName,
                            enable,
                          ),
                      canQuickScheduleOverride: (_) => false,
                      onOpenTask: (taskName) => _openFixedTimeBatchTaskSettings(
                        accountIndex,
                        batchId,
                        taskName,
                        taskName.tr,
                        batchDisplayName: batchDisplayName,
                        returnToBatchPage:
                            _OrchestrationSettingsPage.batchTaskList,
                      ),
                      onQuickRun: (_) async {},
                      onQuickWait: (_) async {},
                    )
                  : enabledTasks.isEmpty
                  ? Center(child: Text('当前顺序任务组还没有任务'.tr))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '长按任务可拖动排序，顺序即该任务组的实际执行顺序。'.tr,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: enabledTasks.length,
                            onReorder: (oldIndex, newIndex) =>
                                _reorderEmbeddedBatchTasks(
                                  accountIndex,
                                  batchId,
                                  enabledTasks,
                                  oldIndex,
                                  newIndex,
                                ),
                            itemBuilder: (context, index) {
                              final task = enabledTasks[index];
                              final taskName = '${task['task_name'] ?? ''}';
                              return ReorderableDelayedDragStartListener(
                                key: ValueKey<String>(
                                  'orchestration-embedded-reorder:$batchId:$taskName',
                                ),
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildFixedSpecialTaskOverviewRow(
                                    accountIndex,
                                    batchId,
                                    task,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _toggleEmbeddedBatchTask(
    int accountIndex,
    String batchId,
    List<Map<String, dynamic>> currentTasks,
    String taskName,
    bool enable,
  ) async {
    final hasEntry = currentTasks.any(
      (task) =>
          _fixedTaskKey('${task['task_name'] ?? ''}') ==
          _fixedTaskKey(taskName),
    );
    final ok = enable && !hasEntry
        ? await ApiClient().addMultiAccountTaskOrchestrationFixedTimeBatchTask(
            scriptName: widget.scriptName,
            accountIndex: accountIndex,
            batchId: batchId,
            taskName: taskName,
          )
        : await ApiClient()
              .setMultiAccountTaskOrchestrationFixedTimeBatchTaskEnable(
                scriptName: widget.scriptName,
                accountIndex: accountIndex,
                batchId: batchId,
                taskName: taskName,
                enable: enable,
              );
    if (ok && mounted) {
      setState(() => _embeddedBatchTaskListGeneration++);
      _reload();
    }
    return ok;
  }

  Future<void> _reorderEmbeddedBatchTasks(
    int accountIndex,
    String batchId,
    List<Map<String, dynamic>> tasks,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final reordered = [...tasks];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    final ok = await ApiClient()
        .reorderMultiAccountTaskOrchestrationSpecialTaskTasks(
          scriptName: widget.scriptName,
          accountIndex: accountIndex,
          batchId: batchId,
          taskNames: reordered
              .map((task) => '${task['task_name'] ?? ''}')
              .where((name) => name.isNotEmpty)
              .toList(),
        );
    if (ok && mounted) {
      setState(() => _embeddedBatchTaskListGeneration++);
      _reload();
    }
  }

  Widget _buildFixedSpecialTaskOverviewRow(
    int accountIndex,
    String batchId,
    Map<String, dynamic> task,
  ) {
    final taskName = '${task['task_name'] ?? ''}'.trim();
    final displayName = '${task['task_display_name'] ?? taskName}'.trim();
    final status = '${task['status'] ?? 'pending'}';
    final type = switch (status) {
      'running' => TaskStatusType.running,
      'completed' || 'failed' || 'unfinished' => TaskStatusType.waiting,
      _ => TaskStatusType.pending,
    };
    return TaskStatusRow(
      key: ValueKey<String>('fixed-batch-status-$batchId-$taskName'),
      controller: widget.controller,
      sourceScriptName: widget.scriptName,
      task: TaskStatusViewData(
        rowId: 'fixed-batch:$batchId:$taskName',
        name: taskName,
        displayName: displayName,
        type: type,
        timeText: _taskStatusLabel(status),
        timeEditable: false,
      ),
      canQuickSchedule: false,
      quickScheduleLocked: true,
      showQuickActions: false,
      leadingActions: [
        TaskStatusActionIcon(
          icon: Icons.fact_check_outlined,
          tooltip: '${'执行状态'.tr}：${_taskStatusLabel(status)}',
          onPressed: () => _showFixedSpecialTaskTaskStatusDialog(
            accountIndex,
            batchId,
            taskName,
            displayName,
            status,
          ),
        ),
      ],
      // “删除”仅停用当前顺序任务组内的任务，私有配置和进度均保留。
      trailingActions: [
        TaskStatusActionIcon(
          icon: Icons.delete_outline_rounded,
          tooltip: '停用任务'.tr,
          onPressed: () async {
            final ok = await ApiClient()
                .setMultiAccountTaskOrchestrationFixedTimeBatchTaskEnable(
                  scriptName: widget.scriptName,
                  accountIndex: accountIndex,
                  batchId: batchId,
                  taskName: taskName,
                  enable: false,
                );
            if (ok) _reload();
          },
        ),
      ],
      onSetNextRun: (_, __) async {},
      onQuickRun: (_) async {},
      onQuickWait: (_) async {},
      onEditTask: (_) async {
        await _openFixedTimeBatchTaskSettings(
          accountIndex,
          batchId,
          taskName,
          displayName,
          batchDisplayName: _batchLabelById(accountIndex, batchId),
          returnToBatchPage: _OrchestrationSettingsPage.batchTaskList,
        );
      },
      onDisableTask: (_) async {
        final ok = await ApiClient()
            .setMultiAccountTaskOrchestrationFixedTimeBatchTaskEnable(
              scriptName: widget.scriptName,
              accountIndex: accountIndex,
              batchId: batchId,
              taskName: taskName,
              enable: false,
            );
        if (ok) _reload();
        return ok;
      },
      onDismissed: (_) {},
      dragEnabled: false,
      swipeEnabled: true,
      activeDragPayload: null,
    );
  }

  Future<void> _showFixedSpecialTaskTaskStatusDialog(
    int accountIndex,
    String batchId,
    String taskName,
    String taskDisplayName,
    String currentStatus,
  ) async {
    var selected = currentStatus;
    final status = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('$taskDisplayName：${'调整执行状态'.tr}'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                ('completed', '今日已完成'),
                ('unfinished', '今日未完成'),
                ('failed', '今日已失败'),
                ('pending', '清除状态'),
              ])
                ChoiceChip(
                  label: Text(item.$2.tr),
                  selected: selected == item.$1,
                  showCheckmark: false,
                  onSelected: (_) => setDialogState(() => selected = item.$1),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('取消'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(selected),
              child: Text('保存'.tr),
            ),
          ],
        ),
      ),
    );
    if (status == null) return;
    if (await ApiClient().setMultiAccountTaskOrchestrationSpecialTaskTaskStatus(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      batchId: batchId,
      taskName: taskName,
      status: status,
    )) {
      if (mounted) {
        setState(() => _embeddedBatchTaskListGeneration++);
      }
      _reload();
    }
  }

  String _fixedTaskFilterLabel(_FixedTaskFilter filter) {
    return switch (filter) {
      _FixedTaskFilter.all => '全部任务'.tr,
      _FixedTaskFilter.enabled => '已启用'.tr,
      _FixedTaskFilter.disabled => '未启用'.tr,
    };
  }

  String _fixedTaskKey(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  Future<void> _openFixedTimeBatchTaskSettings(
    int accountIndex,
    String batchId,
    String taskName,
    String taskDisplayName, {
    String batchDisplayName = '',
    _OrchestrationSettingsPage? returnToBatchPage,
  }) async {
    final data = await ApiClient()
        .getMultiAccountTaskOrchestrationFixedTimeBatchTaskArgs(
          scriptName: widget.scriptName,
          accountIndex: accountIndex,
          batchId: batchId,
          taskName: taskName,
        );
    if (!mounted || data.isEmpty) return;
    final args = Get.find<ArgsController>();
    await args.loadGroupsFromData(
      config: widget.scriptName,
      task: taskName,
      json: data,
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) {
        return ApiClient()
            .putMultiAccountTaskOrchestrationFixedTimeBatchTaskArg(
              scriptName: config,
              accountIndex: accountIndex,
              batchId: batchId,
              taskName: task,
              groupName: group,
              argumentName: argument,
              type: type,
              value: value,
            );
      },
    );
    if (!mounted) return;
    setState(() {
      _settingsPage = _OrchestrationSettingsPage.batchTask;
      _settingsAccountIndex = accountIndex;
      _settingsTaskName = taskName;
      _settingsTaskDisplayName = taskDisplayName;
      _settingsBatchId = batchId;
      _settingsBatchDisplayName = batchDisplayName;
      _returnToBatchPage = returnToBatchPage;
    });
  }

  String _batchLabelById(int accountIndex, String batchId) {
    for (final account in _maps(_liveState.value?['accounts'])) {
      if (account['index'] != accountIndex) continue;
      for (final batch in _maps(account['fixed_time_batches'])) {
        if (batch['batch_id'] == batchId) {
          return '${batch['name'] ?? batch['run_time'] ?? '--:--'}';
        }
      }
    }
    return '顺序任务组'.tr;
  }

  Future<List<String>> _enableDialogTaskNames() async {
    final values = await Future.wait<dynamic>([
      _menuFuture,
      ApiClient().getMultiAccountTaskOrchestrationFixedTimeTasks(
        scriptName: widget.scriptName,
      ),
    ]);
    final menu = values[0] as Map<String, List<String>>;
    final catalog = values[1] as List<Map<String, dynamic>>;
    final supported = {
      for (final task in catalog) _fixedTaskKey('${task['task_name'] ?? ''}'),
    };
    final seen = <String>{};
    return [
      for (final rawTaskName in menu.values.expand((items) => items))
        if (() {
          final taskName = rawTaskName.trim();
          final key = _fixedTaskKey(taskName);
          return taskName.isNotEmpty &&
              supported.contains(key) &&
              seen.add(key);
        }())
          rawTaskName.trim(),
    ];
  }

  Future<void> _showAddTaskDialog(int accountIndex) async {
    final state = await _stateFuture;
    if (!mounted) return;
    final account = _maps(state['accounts']).firstWhere(
      (item) => item['index'] == accountIndex,
      orElse: () => <String, dynamic>{},
    );
    final enabledTaskNames = _maps(account['single_tasks'])
        .where((task) => task['enable'] == true)
        .map((task) => _fixedTaskKey('${task['task_name'] ?? ''}'))
        .toSet();
    final selected = await showMultiAccountEnableTasksDialog(
      context: context,
      title: '${_accountLabel(account)}：${'启用任务'.tr}',
      taskNamesFuture: _enableDialogTaskNames(),
      isTaskEnabled: (taskName) =>
          enabledTaskNames.contains(_fixedTaskKey(taskName)),
    );
    if (selected == null || selected.isEmpty) return;
    for (final taskName in selected) {
      final ok = await ApiClient().addMultiAccountTaskOrchestrationSingleTask(
        scriptName: widget.scriptName,
        accountIndex: accountIndex,
        taskName: taskName,
      );
      if (!ok) return;
    }
    if (mounted) _reload();
  }

  Future<void> _deleteTask(int accountIndex, String taskName) async {
    final confirmed = await _confirm('删除任务'.tr, '删除后会同时清除该账号任务的私有配置，是否继续？'.tr);
    if (confirmed != true) return;
    if (await ApiClient().deleteMultiAccountTaskOrchestrationTask(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
    )) {
      _reload();
    }
  }

  Future<void> _openPublicSettings() async {
    final data = await ApiClient().getMultiAccountTaskOrchestrationPublicArgs(
      scriptName: widget.scriptName,
    );
    if (!mounted || data.isEmpty) return;
    final args = Get.find<ArgsController>();
    await args.loadGroupsFromData(
      config: widget.scriptName,
      task: 'MultiAccountTaskOrchestration',
      json: data,
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) {
        return ApiClient().putMultiAccountTaskOrchestrationPublicArg(
          scriptName: config,
          groupName: group,
          argumentName: argument,
          type: type,
          value: value,
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _settingsPage = _OrchestrationSettingsPage.public;
      _settingsAccountIndex = null;
      _settingsTaskName = '';
      _settingsTaskDisplayName = '';
      _settingsBatchId = '';
      _settingsBatchDisplayName = '';
      _returnToBatchPage = null;
    });
  }

  Future<void> _openTaskSettings(
    int accountIndex,
    String taskName,
    String taskDisplayName,
  ) async {
    setState(() => _loadingTasks.add(taskName));
    final data = await ApiClient().getMultiAccountTaskOrchestrationTaskArgs(
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
        return ApiClient().putMultiAccountTaskOrchestrationTaskArg(
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
    setState(() {
      _settingsPage = _OrchestrationSettingsPage.accountTask;
      _settingsAccountIndex = accountIndex;
      _settingsTaskName = taskName;
      _settingsTaskDisplayName = taskDisplayName;
      _settingsBatchId = '';
      _settingsBatchDisplayName = '';
      _returnToBatchPage = null;
    });
  }

  Future<void> _closeSettingsPage() async {
    final returnToBatchPage = _returnToBatchPage;
    final accountIndex = _settingsAccountIndex;
    final batchId = _settingsBatchId;
    final batchDisplayName = _settingsBatchDisplayName;
    await Get.find<ArgsController>().discardDraftChanges();
    if (!mounted) return;
    setState(() {
      _loadingTasks.remove(_settingsTaskName);
      _settingsPage = _OrchestrationSettingsPage.none;
      _settingsAccountIndex = null;
      _settingsTaskName = '';
      _settingsTaskDisplayName = '';
      _settingsBatchId = '';
      _settingsBatchDisplayName = '';
      _returnToBatchPage = null;
    });
    if (returnToBatchPage == _OrchestrationSettingsPage.batchTaskList &&
        accountIndex != null &&
        batchId.isNotEmpty) {
      _reload();
      _openFixedTimeBatchTaskList(accountIndex, <String, dynamic>{
        'batch_id': batchId,
        'name': batchDisplayName,
      });
      return;
    }
    _reload();
  }

  Widget _buildSettingsPage(BuildContext context) {
    final page = _settingsPage;
    final isAccountTask = page == _OrchestrationSettingsPage.accountTask;
    final isBatchTask = page == _OrchestrationSettingsPage.batchTask;
    final isBatchScheduler = page == _OrchestrationSettingsPage.batchScheduler;
    final isBatchTaskList = page == _OrchestrationSettingsPage.batchTaskList;
    final accountIndex = _settingsAccountIndex;
    final accountLabel = _accountLabelByIndex(accountIndex);
    final taskName = _settingsTaskName;
    final batchLabel = _settingsBatchDisplayName.isNotEmpty
        ? _settingsBatchDisplayName
        : '顺序任务组'.tr;
    final title = switch (page) {
      _OrchestrationSettingsPage.public => '多账号任务编排：${'公共配置'.tr}',
      _OrchestrationSettingsPage.accountTask =>
        '$accountLabel：$_settingsTaskDisplayName：${'账号私有配置'.tr}',
      _OrchestrationSettingsPage.batchScheduler =>
        '$accountLabel：$batchLabel：${'调度器设置'.tr}',
      _OrchestrationSettingsPage.batchTaskList =>
        '$accountLabel：$batchLabel：${'任务列表'.tr}',
      _OrchestrationSettingsPage.batchTask =>
        '$accountLabel：$batchLabel：$_settingsTaskDisplayName：${'任务组私有配置'.tr}',
      _OrchestrationSettingsPage.none => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '返回'.tr,
              onPressed: _closeSettingsPage,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isAccountTask && accountIndex != null && taskName.isNotEmpty)
              IconButton(
                tooltip: '恢复默认配置'.tr,
                onPressed: () async {
                  final ok = await ApiClient()
                      .resetMultiAccountTaskOrchestrationTaskPrivateConfig(
                        scriptName: widget.scriptName,
                        accountIndex: accountIndex,
                        taskName: taskName,
                      );
                  if (ok && mounted) await _closeSettingsPage();
                },
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            if (isBatchTask && accountIndex != null && taskName.isNotEmpty)
              IconButton(
                tooltip: '恢复默认配置'.tr,
                onPressed: () async {
                  final ok = await ApiClient()
                      .resetMultiAccountTaskOrchestrationFixedTimeBatchTaskPrivateConfigToDefault(
                        scriptName: widget.scriptName,
                        accountIndex: accountIndex,
                        batchId: _settingsBatchId,
                        taskName: taskName,
                      );
                  if (ok && mounted) await _closeSettingsPage();
                },
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            if (isAccountTask && accountIndex != null && taskName.isNotEmpty)
              IconButton(
                tooltip: '复制到其他账号'.tr,
                onPressed: () => _showCopyTaskConfigDialog(
                  accountIndex,
                  taskName,
                  _settingsTaskDisplayName,
                ),
                icon: const Icon(Icons.content_copy_rounded),
              ),
          ],
        ),
        if (isBatchScheduler)
          const Padding(
            padding: EdgeInsets.only(left: 48, bottom: 8),
            child: Text('直接使用 OAS 原生 Scheduler：下次运行、优先级、间隔、星期和随机延迟。'),
          )
        else
          const SizedBox(height: 8),
        Expanded(
          child: isBatchTaskList && accountIndex != null
              ? LayoutBuilder(
                  builder: (context, constraints) =>
                      _buildEmbeddedBatchTaskList(
                        context,
                        accountIndex,
                        _settingsBatchId,
                        batchLabel,
                        listHeight: (constraints.maxHeight - 128).clamp(
                          280.0,
                          double.infinity,
                        ),
                      ),
                )
              : Args(
                  scriptName: widget.scriptName,
                  taskName: isAccountTask || isBatchTask
                      ? taskName
                      : 'MultiAccountTaskOrchestration',
                  stagingMode: true,
                  onCancel: _closeSettingsPage,
                ),
        ),
      ],
    );
  }

  String _accountLabelByIndex(int? accountIndex) {
    if (accountIndex == null) return '';
    for (final account in _maps(_liveState.value?['accounts'])) {
      if (account['index'] == accountIndex) return _accountLabel(account);
    }
    return '${'账号'.tr}$accountIndex';
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
        .copyMultiAccountTaskOrchestrationTaskPrivateConfig(
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
        'orchestration',
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
    final future = ApiClient().getMultiAccountTaskOrchestrationAccounts(
      scriptName: widget.scriptName,
    );
    _stateFuture = future;
    _watchState(future);
  }
}
