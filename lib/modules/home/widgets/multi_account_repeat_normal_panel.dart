import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_json_transfer_actions.dart';
import 'package:oasx/modules/home/widgets/task_catalog_row_layout.dart';
import 'package:oasx/modules/home/widgets/multi_account_task_list_layout.dart';
import 'package:oasx/modules/home/widgets/task_status_row.dart';
import 'package:oasx/modules/home/widgets/script_schedule_refresh.dart';
import 'package:oasx/modules/home/widgets/shared_public_account_copy_dialog.dart';
import 'package:oasx/modules/home/widgets/account_management_dialogs.dart';
import 'package:oasx/modules/home/widgets/multi_account_enable_tasks_dialog.dart';
import 'package:oasx/translation/i18n_content.dart';

/// 多账号多任务新普通的独立配置面板。
enum _NewTaskFilter { all, enabled, disabled }

enum _NormalSettingsPage { none, task, public }

enum _NormalAccountProgressAction {
  rerun,
  advancedRecovery,
  lastCompleteTimeChanged,
}

class MultiAccountRepeatNewNormalPanel extends StatefulWidget {
  const MultiAccountRepeatNewNormalPanel({
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
  State<MultiAccountRepeatNewNormalPanel> createState() =>
      _MultiAccountRepeatNewNormalPanelState();
}

class _MultiAccountRepeatNewNormalPanelState
    extends State<MultiAccountRepeatNewNormalPanel> {
  late Future<Map<String, dynamic>> _stateFuture;
  late final Future<Map<String, List<String>>> _menuFuture;
  Worker? _nativeScheduleWorker;
  int _selectedAccount = 1;
  final Set<String> _loadingTasks = <String>{};
  final TextEditingController _taskSearchController = TextEditingController();
  final Set<String> _expandedCatalogGroups = <String>{};
  final Set<String> _togglingCatalogTasks = <String>{};
  String _taskSearchQuery = '';
  bool _showAllTasks = false;
  _NewTaskFilter _taskFilter = _NewTaskFilter.all;
  _NormalSettingsPage _settingsPage = _NormalSettingsPage.none;
  int? _settingsAccountIndex;
  String _settingsTaskName = '';
  String _settingsTaskDisplayName = '';
  String _settingsAccountLabel = '';

  @override
  void initState() {
    super.initState();
    _stateFuture = ApiClient().getMultiAccountRepeatNewNormalAccounts(
      scriptName: widget.scriptName,
    );
    _menuFuture = ApiClient().getScriptMenu();
    _bindNativeScheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant MultiAccountRepeatNewNormalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptName == widget.scriptName) {
      return;
    }
    _selectedAccount = 1;
    _settingsPage = _NormalSettingsPage.none;
    _settingsAccountIndex = null;
    _settingsTaskName = '';
    _settingsTaskDisplayName = '';
    _settingsAccountLabel = '';
    _bindNativeScheduleRefresh();
    _reload();
  }

  @override
  void dispose() {
    _nativeScheduleWorker?.dispose();
    _taskSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_settingsPage != _NormalSettingsPage.none) {
      return _buildSettingsPage(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTaskToolbar(context),
        const SizedBox(height: 10),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _stateFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data ?? const <String, dynamic>{};
              final accounts = _maps(data['accounts']);
              if (accounts.isEmpty) {
                return _buildEmpty(context);
              }
              if (_selectedAccount > accounts.length) {
                _selectedAccount = accounts.length;
              }
              final account = accounts[_selectedAccount - 1];
              return SingleChildScrollView(
                key: PageStorageKey<String>(
                  'multi-account-repeat-normal-content-${widget.scriptName}',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, accounts),
                    const SizedBox(height: 12),
                    _buildAccountContent(context, account),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskToolbar(BuildContext context) {
    final canQuickSchedule =
        widget.controller.isTaskEnabled(
          widget.scriptModel,
          'MultiAccountRepeatNewNormal',
        ) &&
        widget.controller.canQuickScheduleTask(
          widget.scriptModel,
          'MultiAccountRepeatNewNormal',
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
            '多账号多任务新普通'.tr,
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
          taskName: 'MultiAccountRepeatNewNormal',
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
      taskName: 'MultiAccountRepeatNewNormal',
      runNow: runNow,
    );
    if (success) {
      Get.snackbar(I18n.success.tr, '多账号多任务新普通'.tr);
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

  Widget _buildAccountContent(
    BuildContext context,
    Map<String, dynamic> account,
  ) {
    return _buildTaskList(context, account);
  }

  Widget _buildTaskList(BuildContext context, Map<String, dynamic> account) {
    final accountIndex = account['index'] as int? ?? _selectedAccount;
    final configured = _maps(account['tasks']);
    final byName = <String, Map<String, dynamic>>{
      for (final task in configured)
        _normalizeTask('${task['task_name'] ?? ''}'): task,
    };
    final enabled = configured
        .where((task) => task['enabled'] == true)
        .where(_matchesTaskQuery)
        .toList();
    return Card(
      // 与“多账号多任务定时”任务列表直接使用同一套容器配色与 Card 参数。
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
                  tooltip: '账号任务状态与重新运行'.tr,
                  onPressed: () =>
                      _showAccountProgressDialog(accountIndex, account),
                  icon: const Icon(Icons.fact_check_outlined),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskSearchController,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: '搜索任务'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(
                      () => _taskSearchQuery = value.trim().toLowerCase(),
                    ),
                  ),
                ),
                if (_showAllTasks)
                  PopupMenuButton<_NewTaskFilter>(
                    // 与 OAS 实例任务分类页的筛选菜单一致，显式使用当前中文筛选名称作为悬停提示。
                    tooltip: _normalTaskFilterLabel(_taskFilter),
                    initialValue: _taskFilter,
                    onSelected: (value) => setState(() => _taskFilter = value),
                    itemBuilder: (context) => _NewTaskFilter.values
                        .map(
                          (value) => PopupMenuItem<_NewTaskFilter>(
                            value: value,
                            child: Text(_normalTaskFilterLabel(value)),
                          ),
                        )
                        .toList(),
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color: _taskFilter == _NewTaskFilter.all
                          ? null
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: multiAccountTaskListMinHeight,
              child: _showAllTasks
                  ? _buildNormalTaskCatalog(accountIndex, byName)
                  : _buildEnabledNewTasks(accountIndex, enabled),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnabledNewTasks(
    int accountIndex,
    List<Map<String, dynamic>> tasks,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(_taskSearchQuery.isEmpty ? '当前账号尚未添加任务'.tr : '未找到匹配任务'.tr),
      );
    }
    if (_taskSearchQuery.isNotEmpty) {
      return ListView.separated(
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) =>
            _buildEnabledNewTaskRow(accountIndex, tasks[index]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '长按任务可拖动排序，顺序即该账号实际执行顺序。'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) => _reorderEnabledNormalTasks(
              accountIndex,
              tasks,
              oldIndex,
              newIndex,
            ),
            itemBuilder: (_, index) {
              final task = tasks[index];
              final name = '${task['task_name'] ?? ''}';
              return ReorderableDelayedDragStartListener(
                key: ValueKey('normal-reorder:$accountIndex:$name'),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildEnabledNewTaskRow(accountIndex, task),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnabledNewTaskRow(int accountIndex, Map<String, dynamic> task) {
    final name = '${task['task_name'] ?? ''}';
    final title = '${task['task_display_name'] ?? name}';
    final status = '${task['status'] ?? 'pending'}';
    final type = switch (status) {
      'completed' => TaskStatusType.running,
      'failed' || 'unfinished' => TaskStatusType.pending,
      _ => TaskStatusType.waiting,
    };
    return TaskStatusRow(
      key: ValueKey('normal:$accountIndex:$name'),
      controller: widget.controller,
      sourceScriptName: widget.scriptName,
      task: TaskStatusViewData(
        rowId: 'normal:$accountIndex:$name',
        name: name,
        displayName: title,
        type: type,
        timeText: _normalTaskStatusLabel(status),
        timeEditable: false,
      ),
      canQuickSchedule: false,
      quickScheduleLocked: true,
      showQuickActions: false,
      leadingActions: [
        TaskStatusActionIcon(
          icon: Icons.fact_check_outlined,
          tooltip: '${'执行状态'.tr}：${_normalTaskStatusLabel(status)}',
          onPressed: () =>
              _showNormalTaskStatusDialog(accountIndex, name, title, status),
        ),
      ],
      // “删除”仅停用该账号任务，私有配置、状态和排序记录全部保留。
      trailingActions: [
        TaskStatusActionIcon(
          icon: Icons.delete_outline_rounded,
          tooltip: '停用任务'.tr,
          onPressed: () => _setNormalTaskEnabled(accountIndex, name, false),
        ),
      ],
      onSetNextRun: (_, __) async {},
      onQuickRun: (_) async {},
      onQuickWait: (_) async {},
      onEditTask: (_) => _openTaskSettings(accountIndex, name, title),
      onDisableTask: (_) => _setNormalTaskEnabled(accountIndex, name, false),
      onDismissed: (_) {},
      dragEnabled: false,
      swipeEnabled: true,
      activeDragPayload: null,
    );
  }

  Future<void> _reorderEnabledNormalTasks(
    int accountIndex,
    List<Map<String, dynamic>> tasks,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final reordered = [...tasks];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    final ok = await ApiClient().reorderMultiAccountRepeatNewNormalTasks(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskNames: reordered
          .map((task) => '${task['task_name'] ?? ''}')
          .where((name) => name.isNotEmpty)
          .toList(),
    );
    if (ok) _reload();
  }

  String _normalTaskFilterLabel(_NewTaskFilter filter) => switch (filter) {
    _NewTaskFilter.all => '全部任务'.tr,
    _NewTaskFilter.enabled => '已启用'.tr,
    _NewTaskFilter.disabled => '未启用'.tr,
  };

  Future<List<String>> _enableDialogTaskNames() async {
    final menu = await _menuFuture;
    final seen = <String>{};
    return [
      for (final taskName in menu.values.expand((items) => items))
        if (taskName.trim().isNotEmpty && seen.add(_normalizeTask(taskName)))
          taskName.trim(),
    ];
  }

  Future<void> _showEnableTasksDialog(int accountIndex) async {
    final state = await _stateFuture;
    if (!mounted) return;
    final account = _maps(state['accounts']).firstWhere(
      (item) => item['index'] == accountIndex,
      orElse: () => <String, dynamic>{},
    );
    final enabledTaskNames = _maps(account['tasks'])
        .where((task) => task['enabled'] == true)
        .map((task) => _normalizeTask('${task['task_name'] ?? ''}'))
        .toSet();
    final selected = await showMultiAccountEnableTasksDialog(
      context: context,
      title: '${_accountLabel(account)}：${'启用任务'.tr}',
      taskNamesFuture: _enableDialogTaskNames(),
      isTaskEnabled: (taskName) =>
          enabledTaskNames.contains(_normalizeTask(taskName)),
    );
    if (selected == null || selected.isEmpty) return;
    for (final taskName in selected) {
      final ok = await ApiClient().addMultiAccountRepeatNewNormalTask(
        scriptName: widget.scriptName,
        accountIndex: accountIndex,
        taskName: taskName,
      );
      if (!ok) return;
    }
    if (mounted) _reload();
  }

  Widget _buildNormalTaskCatalog(
    int accountIndex,
    Map<String, Map<String, dynamic>> configured,
  ) => FutureBuilder<Map<String, List<String>>>(
    future: _menuFuture,
    builder: (_, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final sections = snapshot.data!.entries
          .map(
            (entry) => MapEntry(
              entry.key,
              entry.value.where((name) {
                if (!_matchesCatalog(name)) return false;
                final enabled =
                    configured[_normalizeTask(name)]?['enabled'] == true;
                return _taskFilter == _NewTaskFilter.all ||
                    (_taskFilter == _NewTaskFilter.enabled) == enabled;
              }).toList(),
            ),
          )
          .where((entry) => entry.value.isNotEmpty)
          .toList();
      if (sections.isEmpty) return Center(child: Text('未找到匹配任务'.tr));
      return ListView.separated(
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _buildNormalCatalogSection(
          accountIndex,
          sections[index].key,
          sections[index].value,
          configured,
        ),
      );
    },
  );

  Widget _buildNormalCatalogSection(
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
                    _buildNormalCatalogTaskRow(
                      accountIndex,
                      groupName,
                      taskNames[index],
                      configured[_normalizeTask(taskNames[index])],
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

  Widget _buildNormalCatalogTaskRow(
    int accountIndex,
    String groupName,
    String taskName,
    Map<String, dynamic>? configured,
  ) {
    final enabled = configured?['enabled'] == true;
    final loading = _togglingCatalogTasks.contains(taskName);
    final isScriptTask = groupName == I18n.script;
    final supportsEnable = !isScriptTask || taskName == 'Restart';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TaskCatalogSplitRow(
        scrollKey: PageStorageKey<String>(
          'multi-account-normal-task-row-$accountIndex-$taskName',
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
            : (value) =>
                  _toggleNormalCatalogTask(accountIndex, taskName, value),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskCatalogIconOnlyButton(
              icon: Icons.tune_rounded,
              tooltip: I18n.homeOpenTaskParams.tr,
              onPressed: () => _openTaskSettings(
                accountIndex,
                '${configured?['task_name'] ?? taskName}',
                taskName.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleNormalCatalogTask(
    int accountIndex,
    String taskName,
    bool enable,
  ) async {
    if (_togglingCatalogTasks.contains(taskName)) return;
    setState(() => _togglingCatalogTasks.add(taskName));
    final ok = await _setNormalTaskEnabled(accountIndex, taskName, enable);
    if (!mounted) return;
    setState(() => _togglingCatalogTasks.remove(taskName));
    if (ok) _reload();
  }

  bool _matchesCatalog(String name) =>
      _taskSearchQuery.isEmpty ||
      name.toLowerCase().contains(_taskSearchQuery) ||
      name.tr.toLowerCase().contains(_taskSearchQuery);
  bool _matchesTaskQuery(Map<String, dynamic> task) =>
      _matchesCatalog('${task['task_name'] ?? ''}') ||
      _matchesCatalog('${task['task_display_name'] ?? ''}');
  String _normalizeTask(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  Future<bool> _setNormalTaskEnabled(
    int accountIndex,
    String taskName,
    bool enable,
  ) async {
    final ok = enable
        ? await ApiClient().addMultiAccountRepeatNewNormalTask(
            scriptName: widget.scriptName,
            accountIndex: accountIndex,
            taskName: taskName,
          )
        : await ApiClient().setMultiAccountRepeatNewNormalTaskEnable(
            scriptName: widget.scriptName,
            accountIndex: accountIndex,
            taskName: taskName,
            enable: false,
          );
    if (ok) _reload();
    return ok;
  }

  List<Map<String, dynamic>> _maps(dynamic value) {
    return value is List
        ? value
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];
  }

  String _normalTaskStatusLabel(String status) => switch (status) {
    'completed' => '今日已完成'.tr,
    'failed' => '今日已失败'.tr,
    'unfinished' => '今日未完成'.tr,
    _ => '未执行'.tr,
  };

  Future<void> _showAccountProgressDialog(
    int accountIndex,
    Map<String, dynamic> account,
  ) async {
    final action = await showDialog<_NormalAccountProgressAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_accountLabel(account)}：${'账号任务状态'.tr}'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'上次完整完成时间'.tr}：${account['last_complete_time'] ?? '-'}'),
              const SizedBox(height: 6),
              Text('${'任务进度记录时间'.tr}：${account['task_progress_time'] ?? '-'}'),
              const SizedBox(height: 12),
              Text(
                '当天的完整完成时间会让该账号跳过；失败或未完成任务会优先恢复。'.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_calendar_outlined),
                title: Text('修改上次完整完成时间'.tr),
                subtitle: Text('使用与调度器相同的时间选择器'.tr),
                trailing: DateTimePicker(
                  value:
                      '${account['last_complete_time'] ?? '2023-01-01 00:00:00'}',
                  minDate: DateTime(2023, 1, 1),
                  maxDate: DateTime(2100, 12, 31, 23, 59, 59),
                  notHoverStyle: Theme.of(context).textTheme.labelLarge,
                  hoverStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onChange: (value) async {
                    final saved = await ApiClient()
                        .setMultiAccountRepeatNewNormalLastCompleteTime(
                          scriptName: widget.scriptName,
                          accountIndex: accountIndex,
                          value: value,
                        );
                    if (saved && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(
                        _NormalAccountProgressAction.lastCompleteTimeChanged,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_NormalAccountProgressAction.advancedRecovery),
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: Text('高级恢复状态管理'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(I18n.cancel.tr),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_NormalAccountProgressAction.rerun),
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text('重新运行此账号'.tr),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == _NormalAccountProgressAction.advancedRecovery) {
      await _showNormalAdvancedRecoveryDialog(accountIndex, account);
      return;
    }
    if (action == _NormalAccountProgressAction.rerun) {
      final confirmed = await _confirm(
        '重新运行此账号',
        '将清除该账号今天的完成、失败和未完成状态；任务及私有配置会保留，并会在下次普通任务运行时从头执行。是否继续？',
      );
      if (confirmed != true) return;
      final saved = await ApiClient().rerunMultiAccountRepeatNewNormalAccount(
        scriptName: widget.scriptName,
        accountIndex: accountIndex,
      );
      if (saved && mounted) {
        Get.snackbar(I18n.success.tr, '已允许该账号重新完整运行'.tr);
      }
    }
    _reload();
  }

  Future<void> _showNormalAdvancedRecoveryDialog(
    int accountIndex,
    Map<String, dynamic> account,
  ) async {
    final rawProgress = account['task_progress'];
    final progress = rawProgress is Map
        ? rawProgress.cast<String, dynamic>()
        : const <String, dynamic>{};
    final completedController = TextEditingController(
      text: '${progress['completed_task_list'] ?? ''}',
    );
    final failedController = TextEditingController(
      text: '${progress['failed_task_list'] ?? ''}',
    );
    final unfinishedController = TextEditingController(
      text: '${progress['unfinished_task_list'] ?? ''}',
    );
    final enabledTasks = _maps(
      account['tasks'],
    ).where((task) => task['enabled'] == true).toList();
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${_accountLabel(account)}：${'高级恢复状态管理'.tr}'),
          content: SizedBox(
            width: 640,
            height: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('可直接编辑旧版同类恢复清单；支持中文任务名、别名或内部任务名。'.tr),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final task in enabledTasks)
                        Chip(
                          avatar: Icon(
                            _normalTaskStatusIcon(
                              '${task['status'] ?? 'pending'}',
                            ),
                            size: 18,
                          ),
                          label: Text(
                            '${task['task_display_name'] ?? task['task_name'] ?? ''}：${_normalTaskStatusLabel('${task['status'] ?? 'pending'}')}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: completedController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: '已完成任务列表'.tr,
                      hintText: '每行一个任务'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: failedController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: '失败任务列表'.tr,
                      hintText: '每行一个任务；下次优先重试'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: unfinishedController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: '未完成任务列表'.tr,
                      hintText: '每行一个任务；下次只继续这些任务'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '仅允许当前账号已启用的任务。重复或冲突时按“失败 ＞ 未完成 ＞ 已完成”处理；保存不会删除私有配置或运行记录。'
                        .tr,
                    style: Theme.of(context).textTheme.bodySmall,
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
            FilledButton.icon(
              onPressed: () async {
                final ok = await ApiClient()
                    .setMultiAccountRepeatNewNormalTaskProgress(
                      scriptName: widget.scriptName,
                      accountIndex: accountIndex,
                      completedTaskList: completedController.text,
                      failedTaskList: failedController.text,
                      unfinishedTaskList: unfinishedController.text,
                    );
                if (ok && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: Text('保存'.tr),
            ),
          ],
        ),
      );
      if (saved == true && mounted) {
        _reload();
      }
    } finally {
      completedController.dispose();
      failedController.dispose();
      unfinishedController.dispose();
    }
  }

  IconData _normalTaskStatusIcon(String status) => switch (status) {
    'completed' => Icons.check_circle_rounded,
    'failed' => Icons.error_outline_rounded,
    'unfinished' => Icons.pending_outlined,
    _ => Icons.radio_button_unchecked_rounded,
  };

  Future<void> _showNormalTaskStatusDialog(
    int accountIndex,
    String taskName,
    String taskDisplayName,
    String currentStatus,
  ) async {
    var selectedStatus = currentStatus;
    final status = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('$taskDisplayName：${'调整执行状态'.tr}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in const [
                        ('completed', '今日已完成'),
                        ('unfinished', '今日未完成（下次只继续此任务）'),
                        ('failed', '今日已失败（下次优先重试此任务）'),
                        ('pending', '清除状态（下次完整运行该账号）'),
                      ])
                        ChoiceChip(
                          label: Text(item.$2.tr),
                          selected: selectedStatus == item.$1,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setDialogState(() => selectedStatus = item.$1),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '修改只影响当前账号的运行记录，不会删除任务或账号私有配置。'.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(selectedStatus),
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
    if (status == null) return;
    if (await ApiClient().setMultiAccountRepeatNewNormalTaskStatus(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
      status: status,
    )) {
      _reload();
    }
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
        (await ApiClient().getMultiAccountRepeatNewNormalPublicAccounts(
          scriptName: widget.scriptName,
        ))['accounts'],
      ),
      onDelete: (identifier) =>
          ApiClient().deleteMultiAccountRepeatNewNormalPublicAccount(
            scriptName: widget.scriptName,
            identifier: identifier,
          ),
      onEdit: _editPublicAccount,
      onAdd: () async {
        final identifier = await _askText('新增公共账号'.tr, '账号标识'.tr);
        if (identifier == null || identifier.trim().isEmpty) return false;
        return ApiClient().addMultiAccountRepeatNewNormalPublicAccount(
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
                      .putMultiAccountRepeatNewNormalPublicAccountValue(
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
        .getMultiAccountRepeatNewNormalPublicAccounts(
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
      await ApiClient().addMultiAccountRepeatNewNormalAccount(
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
      await ApiClient().deleteMultiAccountRepeatNewNormalAccount(
        scriptName: widget.scriptName,
        accountIndex: accountIndex,
      );
    }
    _selectedAccount = 1;
    _reload();
  }

  // ignore: unused_element
  Future<void> _deleteTaskAccount(int accountIndex) async {
    final confirmed = await _confirm(
      '删除账号'.tr,
      '删除后会同时清除该账号下的任务及私有配置，是否继续？'.tr,
    );
    if (confirmed != true) return;
    if (await ApiClient().deleteMultiAccountRepeatNewNormalAccount(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
    )) {
      _selectedAccount = 1;
      _reload();
    }
  }

  // ignore: unused_element
  Future<void> _deleteTask(int accountIndex, String taskName) async {
    final confirmed = await _confirm('删除任务'.tr, '删除后会同时清除该账号任务的私有配置，是否继续？'.tr);
    if (confirmed != true) return;
    if (await ApiClient().deleteMultiAccountRepeatNewNormalTask(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
    )) {
      _reload();
    }
  }

  Future<void> _openPublicSettings() async {
    final data = await ApiClient().getMultiAccountRepeatNewNormalPublicArgs(
      scriptName: widget.scriptName,
    );
    if (!mounted || data.isEmpty) return;
    final args = Get.find<ArgsController>();
    await args.loadGroupsFromData(
      config: widget.scriptName,
      task: 'MultiAccountRepeatNewNormal',
      json: data,
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) {
        return ApiClient().putMultiAccountRepeatNewNormalPublicArg(
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
      _settingsPage = _NormalSettingsPage.public;
      _settingsAccountIndex = null;
      _settingsTaskName = '';
      _settingsTaskDisplayName = '';
      _settingsAccountLabel = '';
    });
  }

  Future<String> _accountLabelByIndex(int accountIndex) async {
    final state = await _stateFuture;
    for (final account in _maps(state['accounts'])) {
      if (account['index'] == accountIndex) {
        return _accountLabel(account);
      }
    }
    return '${'账号'.tr}$accountIndex';
  }

  Future<void> _openTaskSettings(
    int accountIndex,
    String taskName,
    String taskDisplayName,
  ) async {
    setState(() => _loadingTasks.add(taskName));
    final data = await ApiClient().getMultiAccountRepeatNewNormalTaskArgs(
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
        return ApiClient().putMultiAccountRepeatNewNormalTaskArg(
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
    final accountLabel = await _accountLabelByIndex(accountIndex);
    if (!mounted) return;
    setState(() {
      _settingsPage = _NormalSettingsPage.task;
      _settingsAccountIndex = accountIndex;
      _settingsTaskName = taskName;
      _settingsTaskDisplayName = taskDisplayName;
      _settingsAccountLabel = accountLabel;
    });
  }

  Future<void> _closeSettingsPage() async {
    await Get.find<ArgsController>().discardDraftChanges();
    if (!mounted) return;
    setState(() {
      _loadingTasks.remove(_settingsTaskName);
      _settingsPage = _NormalSettingsPage.none;
      _settingsAccountIndex = null;
      _settingsTaskName = '';
      _settingsTaskDisplayName = '';
      _settingsAccountLabel = '';
    });
    _reload();
  }

  Widget _buildSettingsPage(BuildContext context) {
    final isTaskPage = _settingsPage == _NormalSettingsPage.task;
    final accountIndex = _settingsAccountIndex;
    final taskName = _settingsTaskName;
    final title = isTaskPage
        ? '$_settingsAccountLabel：$_settingsTaskDisplayName：${'账号私有配置'.tr}'
        : '多账号多任务新普通：${'公共配置'.tr}';
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
            if (isTaskPage && accountIndex != null && taskName.isNotEmpty)
              IconButton(
                tooltip: '恢复默认配置'.tr,
                onPressed: () async {
                  final ok = await ApiClient()
                      .resetMultiAccountRepeatNewNormalTaskPrivateConfig(
                        scriptName: widget.scriptName,
                        accountIndex: accountIndex,
                        taskName: taskName,
                      );
                  if (ok && mounted) {
                    await _closeSettingsPage();
                  }
                },
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            if (isTaskPage && accountIndex != null && taskName.isNotEmpty)
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
        const SizedBox(height: 8),
        Expanded(
          child: Args(
            scriptName: widget.scriptName,
            taskName: isTaskPage ? taskName : 'MultiAccountRepeatNewNormal',
            stagingMode: true,
            onCancel: _closeSettingsPage,
          ),
        ),
      ],
    );
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
        .copyMultiAccountRepeatNewNormalTaskPrivateConfig(
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

  void _reload() {
    if (!mounted) return;
    setState(() {
      _stateFuture = ApiClient().getMultiAccountRepeatNewNormalAccounts(
        scriptName: widget.scriptName,
      );
    });
  }
}
