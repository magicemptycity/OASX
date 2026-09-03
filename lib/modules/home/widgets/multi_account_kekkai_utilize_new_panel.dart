import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_json_transfer_actions.dart';
import 'package:oasx/modules/home/widgets/task_status_row.dart';
import 'package:oasx/modules/home/widgets/script_schedule_refresh.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/modules/home/widgets/shared_public_account_copy_dialog.dart';
import 'package:oasx/modules/home/widgets/account_management_dialogs.dart';
import 'package:oasx/translation/i18n_content.dart';

/// 新版多账号蹭卡：运行账号使用公共账号库，蹭卡配置与禁卡时段均由账号独立保存。
class MultiAccountKekkaiUtilizeNewPanel extends StatefulWidget {
  const MultiAccountKekkaiUtilizeNewPanel({
    super.key,
    required this.controller,
    required this.scriptModel,
    required this.onBack,
  });

  final HomeDashboardController controller;
  final ScriptModel scriptModel;
  final Future<void> Function() onBack;

  @override
  State<MultiAccountKekkaiUtilizeNewPanel> createState() =>
      _MultiAccountKekkaiUtilizeNewPanelState();
}

class _MultiAccountKekkaiUtilizeNewPanelState
    extends State<MultiAccountKekkaiUtilizeNewPanel> {
  late Future<Map<String, dynamic>> _stateFuture;
  final ScriptService _scriptService = Get.find<ScriptService>();
  Worker? _overviewWorker;
  Worker? _nativeScheduleWorker;
  Map<String, dynamic>? _activeOverviewAccount;
  bool _showDisabledAccounts = false;
  String get _scriptName => widget.scriptModel.name;
  static const _taskName = 'MultiAccountKekkaiUtilizeNew';

  @override
  void initState() {
    super.initState();
    _reload();
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
  void didUpdateWidget(covariant MultiAccountKekkaiUtilizeNewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptModel.name != widget.scriptModel.name) {
      _activeOverviewAccount = null;
      _bindNativeScheduleRefresh();
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canQuickSchedule =
        widget.controller.isTaskEnabled(widget.scriptModel, _taskName) &&
        widget.controller.canQuickScheduleTask(widget.scriptModel, _taskName);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '返回'.tr,
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                '多账号多任务蹭卡新'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: I18n.homeQuickRun.tr,
              onPressed: canQuickSchedule ? () => _quickSchedule(true) : null,
              icon: const Icon(Icons.flash_on_rounded),
            ),
            IconButton(
              tooltip: I18n.homeQuickWait.tr,
              onPressed: canQuickSchedule ? () => _quickSchedule(false) : null,
              icon: const Icon(Icons.schedule_rounded),
            ),
            TaskJsonTransferActions(
              configName: _scriptName,
              taskName: _taskName,
              onImported: _reloadAfterImport,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _stateFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final allAccounts = _maps(snapshot.data?['accounts']);
              final accounts = _showDisabledAccounts
                  ? allAccounts
                  : allAccounts
                        .where((item) => item['enabled'] != false)
                        .toList();
              if (allAccounts.isEmpty) {
                // 没有账号时只显示居中的添加账号卡片，不显示账号管理栏。
                return _buildEmpty(context);
              }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context, allAccounts),
                    const SizedBox(height: 12),
                    for (final account in accounts) ...[
                      _buildAccount(context, account),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<Map<String, dynamic>> accounts,
  ) => Card(
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
                onPressed: _showTaskSettings,
                icon: Icons.settings_rounded,
                label: '公共配置'.tr,
              ),
              IconButton(
                tooltip: _showDisabledAccounts ? '隐藏未启用账号'.tr : '显示未启用账号'.tr,
                onPressed: () => setState(
                  () => _showDisabledAccounts = !_showDisabledAccounts,
                ),
                icon: Icon(
                  _showDisabledAccounts
                      ? Icons.filter_alt_off_rounded
                      : Icons.filter_alt_rounded,
                ),
              ),
              buildAccountManagementButton(
                onPressed: _showAddAccount,
                icon: Icons.person_add_alt_1_rounded,
                label: '添加账号'.tr,
                filled: true,
              ),
              buildAccountManagementButton(
                onPressed: () => _showDeleteAccounts(accounts),
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
        ],
      ),
    ),
  );

  Widget _buildEmpty(BuildContext context) {
    // 与多账号多任务新的空页面保持一致，避免卡片被 Expanded 拉伸成竖长条。
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
                onPressed: _showAddAccount,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text('添加账号'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccount(BuildContext context, Map<String, dynamic> account) {
    final index = account['index'] as int? ?? 0;
    final character = '${account['character'] ?? ''}'.trim();
    final server = '${account['svr'] ?? ''}'.trim();
    final label = [
      character,
      server,
    ].where((item) => item.isNotEmpty).join('-');
    final accountLabel = label.isEmpty
        ? '${account['public_account_identifier'] ?? ''}'.trim()
        : label;
    final nextRun =
        '${account['next_run'] ?? account['next_utilize_time'] ?? ''}'.trim();
    final enabled = account['enabled'] != false;
    final activeIndex = _activeOverviewAccount?['account_index'];
    final isRunning = activeIndex == index;
    final type = isRunning
        ? TaskStatusType.running
        : '${account['schedule_status'] ?? 'waiting'}' == 'pending'
        ? TaskStatusType.pending
        : TaskStatusType.waiting;
    final task = TaskStatusViewData(
      rowId: 'multi-account-utilize::$index',
      name: 'MultiAccountKekkaiUtilizeNew/$index',
      displayName: '$index：$accountLabel',
      type: type,
      timeText: nextRun,
    );
    return TaskStatusRow(
      key: ValueKey(task.rowId),
      controller: widget.controller,
      sourceScriptName: _scriptName,
      task: task,
      canQuickSchedule: enabled && !isRunning,
      quickScheduleLocked: isRunning,
      leadingActions: [
        TaskStatusActionIcon(
          icon: Icons.block_rounded,
          tooltip: '禁卡时段配置'.tr,
          onPressed: () => _showForbidSettings(index, accountLabel),
        ),
        TaskStatusActionIcon(
          icon: Icons.delete_outline_rounded,
          tooltip: '删除账号'.tr,
          onPressed: () => _deleteAccount(index, accountLabel),
        ),
      ],
      onSetNextRun: (_, value) => _setAccountNextRun(index, value),
      onQuickRun: (_) => _quickScheduleAccount(index, runNow: true),
      onQuickWait: (_) => _quickScheduleAccount(index, runNow: false),
      onEditTask: (_) => _showAccountTaskSettings(index, accountLabel),
      onDisableTask: (_) =>
          ApiClient().setMultiAccountKekkaiUtilizeNewAccountEnable(
            scriptName: _scriptName,
            accountIndex: index,
            enable: false,
          ),
      onDismissed: (_) => _reload(),
      dragEnabled: false,
      swipeEnabled: enabled && !isRunning,
      activeDragPayload: null,
    );
  }

  Future<void> _quickSchedule(bool runNow) async {
    final ok = await widget.controller.quickScheduleTask(
      scriptName: _scriptName,
      taskName: _taskName,
      runNow: runNow,
    );
    if (ok && mounted) Get.snackbar(I18n.success.tr, '多账号多任务蹭卡新'.tr);
  }

  Future<void> _showAddAccount() async {
    final data = await ApiClient()
        .getMultiAccountKekkaiUtilizeNewPublicAccounts(scriptName: _scriptName);
    final state = await _stateFuture;
    if (!mounted) return;
    final used = _maps(
      state['accounts'],
    ).map((item) => '${item['public_account_identifier'] ?? ''}').toSet();
    final choices = _maps(
      data['accounts'],
    ).where((item) => !used.contains('${item['identifier'] ?? ''}')).toList();
    final selected = await showMultiAccountPickerDialog(
      context: context,
      choices: choices,
      detailBuilder: _publicAccountDetail,
    );
    if (selected == null || selected.isEmpty) return;
    for (final identifier in selected) {
      await ApiClient().addMultiAccountKekkaiUtilizeNewAccount(
        scriptName: _scriptName,
        identifier: identifier,
      );
    }
    _reload();
  }

  Future<void> _showDeleteAccounts(List<Map<String, dynamic>> accounts) async {
    final indexes = await showBatchAccountDeleteDialog(
      context: context,
      accounts: accounts,
      titleBuilder: _accountLabel,
      detailBuilder: _publicAccountDetail,
    );
    if (indexes == null || indexes.isEmpty || !mounted) return;
    final confirmed = await _confirm(
      '确认批量删除'.tr,
      '只会删除运行账号列表中的账号，不会删除公共账号库中的账号。是否继续？'.tr,
    );
    if (confirmed != true) return;
    final sorted = [...indexes]..sort((a, b) => b.compareTo(a));
    for (final index in sorted) {
      await ApiClient().deleteMultiAccountKekkaiUtilizeNewAccount(
        scriptName: _scriptName,
        accountIndex: index,
      );
    }
    _reload();
  }

  Future<void> _deleteAccount(int index, String label) async {
    final ok = await _confirm('删除账号'.tr, '确认从多账号多任务蹭卡新中删除 $label？'.tr);
    if (ok != true) return;
    if (await ApiClient().deleteMultiAccountKekkaiUtilizeNewAccount(
      scriptName: _scriptName,
      accountIndex: index,
    )) {
      _reload();
    }
  }

  String _accountLabel(Map<String, dynamic> account) {
    final character = '${account['character'] ?? ''}'.trim();
    final server = '${account['svr'] ?? ''}'.trim();
    final identifier = '${account['public_account_identifier'] ?? ''}'.trim();
    final title = [
      character,
      server,
    ].where((item) => item.isNotEmpty).join('-');
    if (title.isNotEmpty) return title;
    return identifier.isEmpty ? '-' : identifier;
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
          scriptName: _scriptName,
        ))['accounts'],
      ),
      onDelete: (identifier) =>
          ApiClient().deleteMultiAccountTaskOrchestrationPublicAccount(
            scriptName: _scriptName,
            identifier: identifier,
          ),
      onEdit: _editPublicAccount,
      onAdd: () async {
        final identifier = await _askText('新增公共账号'.tr, '账号标识'.tr);
        if (identifier == null || identifier.trim().isEmpty) return false;
        return ApiClient().addMultiAccountTaskOrchestrationPublicAccount(
          scriptName: _scriptName,
          identifier: identifier.trim(),
        );
      },
      detailBuilder: _publicAccountDetail,
      onCopy: (accounts) => showSharedPublicAccountCopyDialog(
        context: context,
        sourceScriptName: _scriptName,
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
                        scriptName: _scriptName,
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

  Future<void> _setAccountNextRun(int index, String nextRun) async {
    final ok = await ApiClient().putMultiAccountKekkaiUtilizeNewSchedulerArg(
      scriptName: _scriptName,
      accountIndex: index,
      argumentName: 'next_run',
      type: 'date_time',
      value: nextRun,
    );
    if (ok) _reload();
  }

  Future<void> _quickScheduleAccount(int index, {required bool runNow}) async {
    final ok = await ApiClient()
        .quickScheduleMultiAccountKekkaiUtilizeNewAccount(
          scriptName: _scriptName,
          accountIndex: index,
          runNow: runNow,
        );
    if (ok) _reload();
  }

  Future<void> _showAccountTaskSettings(int index, String label) async {
    final results = await Future.wait([
      ApiClient().getMultiAccountKekkaiUtilizeNewSchedulerArgs(
        scriptName: _scriptName,
        accountIndex: index,
      ),
      ApiClient().getMultiAccountKekkaiUtilizeNewUtilizeArgs(
        scriptName: _scriptName,
        accountIndex: index,
      ),
    ]);
    if (!mounted || results.any((data) => data.isEmpty)) return;
    final args = Get.find<ArgsController>();
    await args.loadGroupsFromData(
      config: _scriptName,
      task: _taskName,
      json: {...results[0], ...results[1]},
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) {
        if (group == 'scheduler') {
          return ApiClient().putMultiAccountKekkaiUtilizeNewSchedulerArg(
            scriptName: config,
            accountIndex: index,
            argumentName: argument,
            type: type,
            value: value,
          );
        }
        return ApiClient().putMultiAccountKekkaiUtilizeNewUtilizeArg(
          scriptName: config,
          accountIndex: index,
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
                title: Text('$label：${'蹭卡任务设置'.tr}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: '恢复默认私有蹭卡配置'.tr,
                      onPressed: () async {
                        if (await ApiClient()
                                .resetMultiAccountKekkaiUtilizeNewUtilizeArgs(
                                  scriptName: _scriptName,
                                  accountIndex: index,
                                ) &&
                            dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                    ),
                    IconButton(
                      tooltip: '复制私有蹭卡配置'.tr,
                      onPressed: () => _showCopyDialog(index, label, false),
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
                  scriptName: _scriptName,
                  taskName: _taskName,
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

  Future<void> _showTaskSettings() async {
    final data = await ApiClient().getMultiAccountKekkaiUtilizeNewPublicArgs(
      scriptName: _scriptName,
    );
    if (data.isEmpty || !mounted) return;
    final args = Get.find<ArgsController>();
    await args.loadGroupsFromData(
      config: _scriptName,
      task: _taskName,
      json: data,
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) =>
          ApiClient().putMultiAccountKekkaiUtilizeNewPublicArg(
            scriptName: config,
            groupName: group,
            argumentName: argument,
            type: type,
            value: value,
          ),
    );
    if (!mounted) return;
    await _showArgsDialog(args, '多账号多任务蹭卡新任务设置'.tr);
  }

  Future<void> _showForbidSettings(int index, String label) async {
    final data = await ApiClient().getMultiAccountKekkaiUtilizeNewForbidPeriods(
      scriptName: _scriptName,
      accountIndex: index,
    );
    if (!mounted) return;
    final periods = _maps(data['periods']);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: SizedBox(
            width: 620,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$label：${'禁卡时段配置'.tr}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: '添加禁止时段'.tr,
                        onPressed: () async {
                          if (await ApiClient()
                              .addMultiAccountKekkaiUtilizeNewForbidPeriod(
                                scriptName: _scriptName,
                                accountIndex: index,
                              )) {
                            setDialogState(
                              () => periods.add({
                                'index': periods.length + 1,
                                'start': '00:00:00',
                                'end': '00:00:00',
                              }),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                      IconButton(
                        tooltip: '复制到其他账号'.tr,
                        onPressed: () => _showCopyDialog(index, label, true),
                        icon: const Icon(Icons.content_copy_rounded),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (periods.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('暂未添加禁卡时段，账号可随时蹭卡。'.tr),
                    )
                  else
                    ...periods.map(
                      (period) => _buildForbidPeriodRow(
                        context: context,
                        accountIndex: index,
                        period: period,
                        onChanged: () => setDialogState(() {}),
                        onDeleted: () => setDialogState(() {
                          periods.remove(period);
                          for (var i = 0; i < periods.length; i++) {
                            periods[i]['index'] = i + 1;
                          }
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    _reload();
  }

  Widget _buildForbidPeriodRow({
    required BuildContext context,
    required int accountIndex,
    required Map<String, dynamic> period,
    required VoidCallback onChanged,
    required VoidCallback onDeleted,
  }) {
    final periodIndex = period['index'] as int? ?? 0;
    Future<void> pick(bool isStart) async {
      final current = _parseTime('${period[isStart ? 'start' : 'end']}');
      final value = await showTimePicker(
        context: context,
        initialTime: current,
      );
      if (value == null) return;
      final updated = _formatTime(value);
      final start = isStart ? updated : '${period['start']}';
      final end = isStart ? '${period['end']}' : updated;
      if (await ApiClient().updateMultiAccountKekkaiUtilizeNewForbidPeriod(
        scriptName: _scriptName,
        accountIndex: accountIndex,
        periodIndex: periodIndex,
        start: start,
        end: end,
      )) {
        period[isStart ? 'start' : 'end'] = updated;
        onChanged();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('${'时段'.tr} $periodIndex'),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => pick(true),
            icon: const Icon(Icons.schedule_rounded, size: 16),
            label: Text('${period['start']}'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('—'),
          ),
          OutlinedButton.icon(
            onPressed: () => pick(false),
            icon: const Icon(Icons.schedule_rounded, size: 16),
            label: Text('${period['end']}'),
          ),
          const Spacer(),
          IconButton(
            tooltip: '删除'.tr,
            onPressed: () async {
              if (await ApiClient()
                  .deleteMultiAccountKekkaiUtilizeNewForbidPeriod(
                    scriptName: _scriptName,
                    accountIndex: accountIndex,
                    periodIndex: periodIndex,
                  )) {
                onDeleted();
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _showCopyDialog(
    int sourceIndex,
    String sourceLabel,
    bool forbid,
  ) async {
    final data = await ApiClient().getMultiAccountKekkaiUtilizeNewAccounts(
      scriptName: _scriptName,
    );
    if (!mounted) return;
    final candidates = _maps(
      data['accounts'],
    ).where((account) => account['index'] != sourceIndex).toList();
    final selectedIndexes = <int>{};
    final targets = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('复制${forbid ? '禁卡时段配置'.tr : '私有蹭卡配置'.tr}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('$sourceLabel ${'的配置将复制到所选账号。'.tr}'),
                ),
                const SizedBox(height: 8),
                ...candidates.map((account) {
                  final accountIndex = account['index'] as int? ?? 0;
                  final label =
                      '${account['character'] ?? ''}-${account['svr'] ?? ''}';
                  return CheckboxListTile(
                    value: selectedIndexes.contains(accountIndex),
                    onChanged: (value) => setDialogState(() {
                      if (value == true) {
                        selectedIndexes.add(accountIndex);
                      } else {
                        selectedIndexes.remove(accountIndex);
                      }
                    }),
                    title: Text('$accountIndex：$label'),
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
    if (targets == null || targets.isEmpty) return;
    final ok = forbid
        ? await ApiClient().copyMultiAccountKekkaiUtilizeNewForbidPeriods(
            scriptName: _scriptName,
            accountIndex: sourceIndex,
            targetAccountIndexes: targets,
          )
        : await ApiClient().copyMultiAccountKekkaiUtilizeNewUtilizeArgs(
            scriptName: _scriptName,
            accountIndex: sourceIndex,
            targetAccountIndexes: targets,
          );
    if (ok && mounted) {
      Get.snackbar(I18n.success.tr, '已复制到${targets.length}个账号'.tr);
      _reload();
    }
  }

  Future<void> _showArgsDialog(
    ArgsController args,
    String title, {
    Future<bool> Function()? reset,
    Future<void> Function()? copy,
  }) async {
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
                trailing: Wrap(
                  children: [
                    if (reset != null)
                      IconButton(
                        tooltip: '恢复默认配置'.tr,
                        onPressed: () async {
                          if (await reset() && dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        icon: const Icon(Icons.restart_alt_rounded),
                      ),
                    if (copy != null)
                      IconButton(
                        tooltip: '复制到其他账号'.tr,
                        onPressed: copy,
                        icon: const Icon(Icons.content_copy_rounded),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Args(
                  scriptName: _scriptName,
                  taskName: _taskName,
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

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
  }

  String _formatTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';

  Future<void> _reloadAfterImport() async => _reload();

  Future<bool?> _confirm(String title, String message) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(I18n.cancel.tr),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(I18n.confirm.tr),
        ),
      ],
    ),
  );

  List<Map<String, dynamic>> _maps(dynamic raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList()
      : <Map<String, dynamic>>[];

  void _bindNativeScheduleRefresh() {
    _nativeScheduleWorker?.dispose();
    _nativeScheduleWorker = bindNativeScheduleRefresh(
      widget.scriptModel,
      _reload,
    );
  }

  void _bindOverviewPush() {
    _overviewWorker?.dispose();
    _overviewWorker = ever(_scriptService.multiAccountOverviewEvents, (_) {
      final event = _scriptService.multiAccountOverviewEvent(
        _scriptName,
        'utilize',
      );
      if (event == null) return;
      if (event.containsKey('active')) {
        final active = event['active'];
        _activeOverviewAccount = active is Map
            ? active.cast<String, dynamic>()
            : null;
      }
      _reload();
    });
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _stateFuture = ApiClient().getMultiAccountKekkaiUtilizeNewAccounts(
        scriptName: _scriptName,
      );
    });
  }
}
