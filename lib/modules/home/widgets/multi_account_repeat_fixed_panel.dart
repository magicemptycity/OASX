import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_json_transfer_actions.dart';
import 'package:oasx/modules/home/widgets/shared_public_account_copy_dialog.dart';
import 'package:oasx/translation/i18n_content.dart';

/// 多账号多任务新固定时间的独立配置面板。
class MultiAccountRepeatNewFixedPanel extends StatefulWidget {
  const MultiAccountRepeatNewFixedPanel({
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
  State<MultiAccountRepeatNewFixedPanel> createState() =>
      _MultiAccountRepeatNewFixedPanelState();
}

class _MultiAccountRepeatNewFixedPanelState
    extends State<MultiAccountRepeatNewFixedPanel> {
  late Future<Map<String, dynamic>> _stateFuture;
  int _selectedAccount = 1;
  final Set<String> _loadingTasks = <String>{};

  @override
  void initState() {
    super.initState();
    _stateFuture = ApiClient().getMultiAccountRepeatNewFixedAccounts(
      scriptName: widget.scriptName,
    );
  }

  @override
  void didUpdateWidget(covariant MultiAccountRepeatNewFixedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptName == widget.scriptName) {
      return;
    }
    _selectedAccount = 1;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, accounts),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildAccountContent(context, account),
                    ),
                  ),
                ],
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
          'MultiAccountRepeatNewFixed',
        ) &&
        widget.controller.canQuickScheduleTask(
          widget.scriptModel,
          'MultiAccountRepeatNewFixed',
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
            '多账号多任务新固定时间'.tr,
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
          taskName: 'MultiAccountRepeatNewFixed',
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
      taskName: 'MultiAccountRepeatNewFixed',
      runNow: runNow,
    );
    if (success) {
      Get.snackbar(I18n.success.tr, '多账号多任务新固定时间'.tr);
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
                OutlinedButton.icon(
                  onPressed: _showPublicAccounts,
                  icon: const Icon(Icons.groups_rounded, size: 18),
                  label: Text('公共账号库'.tr),
                ),
                OutlinedButton.icon(
                  onPressed: _showPublicSettings,
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: Text('公共配置'.tr),
                ),
                FilledButton.icon(
                  onPressed: _showAddTaskAccount,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text('添加账号'.tr),
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
    return _buildFixedTimeBatches(context, account);
  }

  Widget _buildFixedTimeBatches(
    BuildContext context,
    Map<String, dynamic> account,
  ) {
    final accountIndex = account['index'] as int? ?? _selectedAccount;
    final batches = _maps(account['fixed_time_batches']);
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
                    '${_accountLabel(account)}：固定时间任务',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '删除账号'.tr,
                  onPressed: () => _deleteTaskAccount(accountIndex),
                  icon: const Icon(Icons.person_remove_outlined),
                ),
                FilledButton.icon(
                  onPressed: () => _addFixedTimeBatch(accountIndex),
                  icon: const Icon(Icons.add_alarm_rounded, size: 18),
                  label: const Text('添加时间批次'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '时间批次和其中的任务、私有配置均只作用于当前账号。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (batches.isEmpty)
              Text(
                '当前账号未设置固定时间任务。',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...batches.map(
                (batch) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildFixedTimeBatchItem(context, accountIndex, batch),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedTimeBatchItem(
    BuildContext context,
    int accountIndex,
    Map<String, dynamic> batch,
  ) {
    final batchId = '${batch['batch_id'] ?? ''}';
    final enabled = batch['enable'] == true;
    final tasks = _maps(batch['tasks']);
    final canEdit = batchId.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 为上下两个主按钮预留同样的宽度；右侧图标与开关不参与按钮宽度计算。
          final controlWidth = (constraints.maxWidth - 104).clamp(0.0, double.infinity).toDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: controlWidth,
                    child: OutlinedButton.icon(
                      onPressed: !canEdit
                          ? null
                          : () => _editFixedTimeBatchTime(accountIndex, batch),
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: Text(
                        _batchScheduleLabel(batch),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: '复制到其他账号'.tr,
                    onPressed: !canEdit
                        ? null
                        : () => _showCopyFixedTimeBatchDialog(
                              accountIndex,
                              batchId,
                            ),
                    icon: const Icon(Icons.content_copy_rounded),
                  ),
                  IconButton(
                    tooltip: '删除时间批次',
                    onPressed: !canEdit
                        ? null
                        : () => _deleteFixedTimeBatch(accountIndex, batchId),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: controlWidth,
                    child: OutlinedButton.icon(
                      onPressed: !canEdit
                          ? null
                          : () => _showFixedTimeBatchTaskListDialog(
                                accountIndex,
                                batch,
                              ),
                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                      label: Text('任务列表（${tasks.length}）'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: enabled,
                    onChanged: !canEdit
                        ? null
                        : (value) async {
                            if (await ApiClient()
                                .setMultiAccountRepeatNewFixedFixedTimeBatchEnable(
                                  scriptName: widget.scriptName,
                                  accountIndex: accountIndex,
                                  batchId: batchId,
                                  enable: value,
                                )) {
                              _reload();
                            }
                          },
                  ),
                ],
              ),
            ],
          );
        },
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
            final searchText = '${_accountLabel(account)} ${_accountPickerDetail(account)}'.toLowerCase();
            return query.isEmpty || searchText.contains(query);
          }).toList();
          return AlertDialog(
            title: const Text('复制固定时间批次'),
            content: SizedBox(
              width: 460,
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('将复制时间和周期、启用状态、批次任务及其私有配置；不会复制任务状态、运行记录和上次成功时间。'),
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
                                subtitle: Text(_accountPickerDetail(account)),
                                controlAffinity: ListTileControlAffinity.leading,
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
    final success = await ApiClient().copyMultiAccountRepeatNewFixedFixedTimeBatch(
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
                                : () => _showTaskSettings(
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

  Future<int?> _showAccountPicker(
    List<Map<String, dynamic>> accounts,
  ) async {
    var keyword = '';
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final query = keyword.trim().toLowerCase();
          final visibleAccounts = accounts.where((account) {
            final searchText = '${_accountLabel(account)} ${account['account'] ?? ''}'.toLowerCase();
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
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final account = visibleAccounts[index];
                              final accountIndex = account['index'] as int? ?? 0;
                              return ListTile(
                                selected: accountIndex == _selectedAccount,
                                leading: Icon(
                                  accountIndex == _selectedAccount
                                      ? Icons.check_circle_rounded
                                      : Icons.account_circle_outlined,
                                ),
                                title: Text(_accountLabel(account)),
                                subtitle: Text(_accountPickerDetail(account)),
                                onTap: () => Navigator.of(dialogContext).pop(accountIndex),
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
    final data = await ApiClient().getMultiAccountRepeatNewFixedPublicAccounts(
      scriptName: widget.scriptName,
    );
    if (!mounted) return;
    final accounts = _maps(data['accounts']);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('公共账号库'.tr),
        content: SizedBox(
          width: 620,
          height: 480,
          child: accounts.isEmpty
              ? Center(child: Text('暂无公共账号'.tr))
              : ListView.separated(
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final identifier = '${account['identifier'] ?? ''}';
                    return ListTile(
                      title: Text(identifier),
                      subtitle: Text(_publicAccountDetail(account)),
                      isThreeLine: true,
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: '设置'.tr,
                            onPressed: () async {
                              final saved = await _editPublicAccount(account);
                              if (saved && dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            tooltip: '删除'.tr,
                            onPressed: () async {
                              final ok = await ApiClient()
                                  .deleteMultiAccountRepeatNewFixedPublicAccount(
                                    scriptName: widget.scriptName,
                                    identifier: identifier,
                                  );
                              if (ok && dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton.icon(
            onPressed: accounts.isEmpty
                ? null
                : () async {
                    final copied = await showSharedPublicAccountCopyDialog(
                      context: dialogContext,
                      sourceScriptName: widget.scriptName,
                      accounts: accounts,
                    );
                    if (copied && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
            icon: const Icon(Icons.content_copy_rounded),
            label: const Text('复制到其他脚本'),
          ),
          TextButton.icon(
            onPressed: () async {
              final identifier = await _askText('新增公共账号'.tr, '账号标识'.tr);
              if (identifier == null || identifier.trim().isEmpty) return;
              final ok = await ApiClient()
                  .addMultiAccountRepeatNewFixedPublicAccount(
                    scriptName: widget.scriptName,
                    identifier: identifier.trim(),
                  );
              if (ok && dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: Text('新增公共账号'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('关闭'.tr),
          ),
        ],
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
                      .putMultiAccountRepeatNewFixedPublicAccountValue(
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
        .getMultiAccountRepeatNewFixedPublicAccounts(
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
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('选择公共账号'.tr),
        content: SizedBox(
          width: 420,
          height: 440,
          child: choices.isEmpty
              ? Center(child: Text('没有可添加的公共账号'.tr))
              : ListView.builder(
                  itemCount: choices.length,
                  itemBuilder: (context, index) {
                    final item = choices[index];
                    final identifier = '${item['identifier'] ?? ''}';
                    return ListTile(
                      title: Text(identifier),
                      subtitle: Text(_publicAccountDetail(item)),
                      isThreeLine: true,
                      onTap: () => Navigator.of(dialogContext).pop(identifier),
                    );
                  },
                ),
        ),
      ),
    );
    if (selected == null) return;
    if (await ApiClient().addMultiAccountRepeatNewFixedAccount(
      scriptName: widget.scriptName,
      publicAccountIdentifier: selected,
    )) {
      _reload();
    }
  }

  Future<void> _deleteTaskAccount(int accountIndex) async {
    final confirmed = await _confirm(
      '删除账号'.tr,
      '删除后会同时清除该账号下的任务及私有配置，是否继续？'.tr,
    );
    if (confirmed != true) return;
    if (await ApiClient().deleteMultiAccountRepeatNewFixedAccount(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
    )) {
      _selectedAccount = 1;
      _reload();
    }
  }

  Future<void> _addFixedTimeBatch(int accountIndex) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    if (await ApiClient().addMultiAccountRepeatNewFixedFixedTimeBatch(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      runTime: _formatTimeOfDay(time),
    )) {
      _reload();
    }
  }

  String _batchScheduleLabel(Map<String, dynamic> batch) {
    final runTime = '${batch['run_time'] ?? '--:--'}';
    final mode = '${batch['schedule_mode'] ?? 'daily'}';
    if (mode == 'interval') {
      final interval = batch['interval_days'] as int? ?? 1;
      return '每隔$interval天 · $runTime';
    }
    if (mode == 'weekday') {
      final weekdays = (batch['weekdays'] as List? ?? const [])
          .map((value) => int.tryParse('$value'))
          .whereType<int>()
          .toList();
      return '${_weekdaysLabel(weekdays)} · $runTime';
    }
    return '每天 · $runTime';
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
    return values.isEmpty ? '未选择星期' : values.map((day) => labels[day]).join('、');
  }

  Future<void> _editFixedTimeBatchTime(
    int accountIndex,
    Map<String, dynamic> batch,
  ) async {
    final batchId = '${batch['batch_id'] ?? ''}';
    if (batchId.isEmpty) return;
    var selectedTime = _parseTimeOfDay('${batch['run_time'] ?? '09:00'}');
    var scheduleMode = '${batch['schedule_mode'] ?? 'daily'}';
    if (!{'daily', 'interval', 'weekday'}.contains(scheduleMode)) {
      scheduleMode = 'daily';
    }
    final intervalController = TextEditingController(
      text: '${batch['interval_days'] ?? 1}',
    );
    final selectedWeekdays = <int>{
      for (final value in (batch['weekdays'] as List? ?? const []))
        if (int.tryParse('$value') case final day? when day >= 1 && day <= 7)
          day,
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('固定时间运行规则'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('运行时间', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final value = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (value != null) {
                        setDialogState(() => selectedTime = value);
                      }
                    },
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(_formatTimeOfDay(selectedTime)),
                  ),
                  const SizedBox(height: 12),
                  Text('运行周期', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '选择运行周期',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: scheduleMode,
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('每天运行')),
                          DropdownMenuItem(value: 'interval', child: Text('按间隔天数运行')),
                          DropdownMenuItem(value: 'weekday', child: Text('指定星期运行')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => scheduleMode = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (scheduleMode == 'interval')
                    TextField(
                      controller: intervalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '间隔天数（1-365）',
                        helperText: '例如 2 表示本次完成后两天再运行。',
                      ),
                    ),
                  if (scheduleMode == 'weekday')
                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 4),
                      child: Text('仅在选择的星期到达上述时间后运行。'),
                    ),
                  if (scheduleMode == 'weekday')
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final item in const [
                          (1, '周一'),
                          (2, '周二'),
                          (3, '周三'),
                          (4, '周四'),
                          (5, '周五'),
                          (6, '周六'),
                          (7, '周日'),
                        ])
                          FilterChip(
                            label: Text(item.$2),
                            selected: selectedWeekdays.contains(item.$1),
                            onSelected: (selected) => setDialogState(() {
                              if (selected) {
                                selectedWeekdays.add(item.$1);
                              } else {
                                selectedWeekdays.remove(item.$1);
                              }
                            }),
                          ),
                      ],
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
                final intervalDays = int.tryParse(intervalController.text) ?? 0;
                if (scheduleMode == 'interval' &&
                    (intervalDays < 1 || intervalDays > 365)) {
                  Get.snackbar(I18n.tip.tr, '间隔天数必须在 1 到 365 之间');
                  return;
                }
                if (scheduleMode == 'weekday' && selectedWeekdays.isEmpty) {
                  Get.snackbar(I18n.tip.tr, '请至少选择一个星期');
                  return;
                }
                final ok = await ApiClient()
                    .setMultiAccountRepeatNewFixedFixedTimeBatchSchedule(
                      scriptName: widget.scriptName,
                      accountIndex: accountIndex,
                      batchId: batchId,
                      runTime: _formatTimeOfDay(selectedTime),
                      scheduleMode: scheduleMode,
                      intervalDays: intervalDays.clamp(1, 365),
                      weekdays: selectedWeekdays.toList()..sort(),
                    );
                if (ok && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: Text(I18n.confirm.tr),
            ),
          ],
        ),
      ),
    );
    intervalController.dispose();
    if (saved == true) _reload();
  }

  TimeOfDay _parseTimeOfDay(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 9;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  String _formatTimeOfDay(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _deleteFixedTimeBatch(int accountIndex, String batchId) async {
    final confirmed = await _confirm(
      '删除时间批次',
      '删除后会一并删除该批次的任务、私有配置和运行记录，是否继续？',
    );
    if (confirmed != true) return;
    if (await ApiClient().deleteMultiAccountRepeatNewFixedFixedTimeBatch(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      batchId: batchId,
    )) {
      _reload();
    }
  }

  Future<void> _showFixedTimeBatchTaskListDialog(
    int accountIndex,
    Map<String, dynamic> batch,
  ) async {
    final batchId = '${batch['batch_id'] ?? ''}';
    if (batchId.isEmpty) return;
    final tasks = _maps(batch['tasks']);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${batch['run_time'] ?? '--:--'} 任务列表'),
        content: SizedBox(
          width: 520,
          height: 460,
          child: tasks.isEmpty
              ? const Center(child: Text('当前批次还没有任务'))
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final taskName = '${task['task_name'] ?? ''}'.trim();
                    final displayName =
                        '${task['task_display_name'] ?? taskName}'.trim();
                    final status = '${task['status'] ?? 'pending'}';
                    return ListTile(
                      leading: Icon(
                        _taskStatusIcon(status),
                        color: _taskStatusColor(context, status),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(displayName)),
                          const SizedBox(width: 8),
                          _buildTaskStatusBadge(context, status),
                        ],
                      ),
                      subtitle: Text(_taskStatusLabel(status)),
                      trailing: Wrap(
                        spacing: 2,
                        children: [
                          IconButton(
                            tooltip: '设置批次私有配置',
                            icon: const Icon(Icons.settings_rounded),
                            onPressed: taskName.isEmpty
                                ? null
                                : () async {
                                    Navigator.of(dialogContext).pop();
                                    await _showFixedTimeBatchTaskSettings(
                                      accountIndex,
                                      batchId,
                                      taskName,
                                      displayName,
                                    );
                                  },
                          ),
                          IconButton(
                            tooltip: '删除任务',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: taskName.isEmpty
                                ? null
                                : () async {
                                    Navigator.of(dialogContext).pop();
                                    await _deleteFixedTimeBatchTask(
                                      accountIndex,
                                      batchId,
                                      taskName,
                                    );
                                  },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _showAddFixedTimeBatchTaskDialog(
                accountIndex,
                batchId,
                tasks,
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('添加任务'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('关闭'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFixedTimeBatchTaskDialog(
    int accountIndex,
    String batchId,
    List<Map<String, dynamic>> existingTasks,
  ) async {
    final catalog = await ApiClient()
        .getMultiAccountRepeatNewFixedFixedTimeTasks(
          scriptName: widget.scriptName,
        );
    if (!mounted) return;
    final existing = existingTasks
        .map((task) => '${task['task_name'] ?? ''}'.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    final selected = <String>{};
    final searchController = TextEditingController();
    var keyword = '';
    final selectedTasks = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final normalized = keyword.trim().toLowerCase();
          final filtered = catalog.where((task) {
            final name = '${task['task_name'] ?? ''}'.toLowerCase();
            final display = '${task['task_display_name'] ?? name}'
                .toLowerCase();
            return normalized.isEmpty ||
                name.contains(normalized) ||
                display.contains(normalized);
          }).toList();
          return AlertDialog(
            title: const Text('添加固定时间任务'),
            content: SizedBox(
              width: 520,
              height: 560,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: '搜索所有任务',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setDialogState(() => keyword = value),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        final taskName = '${task['task_name'] ?? ''}'.trim();
                        final displayName =
                            '${task['task_display_name'] ?? taskName}'.trim();
                        final alreadyAdded = existing.contains(taskName);
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: alreadyAdded || selected.contains(taskName),
                          title: Text(displayName),
                          subtitle: alreadyAdded ? const Text('已添加') : null,
                          onChanged: alreadyAdded || taskName.isEmpty
                              ? null
                              : (checked) => setDialogState(() {
                                  if (checked == true) {
                                    selected.add(taskName);
                                  } else {
                                    selected.remove(taskName);
                                  }
                                }),
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
                child: Text('取消'.tr),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.of(dialogContext).pop(selected.toList()),
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
    searchController.dispose();
    if (selectedTasks == null || selectedTasks.isEmpty) return;
    for (final taskName in selectedTasks) {
      final ok = await ApiClient()
          .addMultiAccountRepeatNewFixedFixedTimeBatchTask(
            scriptName: widget.scriptName,
            accountIndex: accountIndex,
            batchId: batchId,
            taskName: taskName,
          );
      if (!ok) return;
    }
    _reload();
  }

  Future<void> _deleteFixedTimeBatchTask(
    int accountIndex,
    String batchId,
    String taskName,
  ) async {
    if (await ApiClient().deleteMultiAccountRepeatNewFixedFixedTimeBatchTask(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      batchId: batchId,
      taskName: taskName,
    )) {
      _reload();
    }
  }

  Future<void> _showFixedTimeBatchTaskSettings(
    int accountIndex,
    String batchId,
    String taskName,
    String taskDisplayName,
  ) async {
    final data = await ApiClient()
        .getMultiAccountRepeatNewFixedFixedTimeBatchTaskArgs(
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
        return ApiClient().putMultiAccountRepeatNewFixedFixedTimeBatchTaskArg(
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
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 720,
          height: 680,
          child: Column(
            children: [
              ListTile(
                title: Text('$taskDisplayName：批次私有配置'),
                subtitle: const Text('只对当前账号的当前时间批次生效。'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: '恢复默认配置'.tr,
                      onPressed: () async {
                        final ok = await ApiClient()
                            .resetMultiAccountRepeatNewFixedFixedTimeBatchTaskPrivateConfigToDefault(
                              scriptName: widget.scriptName,
                              accountIndex: accountIndex,
                              batchId: batchId,
                              taskName: taskName,
                            );
                        if (ok && dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
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
    if (mounted) _reload();
  }

  Future<void> _showAddTaskDialog(int accountIndex) async {
    // 使用后端提供的可执行任务目录，任务名与已添加记录均为统一的下划线格式。
    // 这样已添加任务能被正确识别并禁用，避免重复选择。
    final catalog = await ApiClient()
        .getMultiAccountRepeatNewFixedFixedTimeTasks(
          scriptName: widget.scriptName,
        );
    final state = await _stateFuture;
    if (!mounted) return;
    final account = _maps(state['accounts']).firstWhere(
      (item) => item['index'] == accountIndex,
      orElse: () => <String, dynamic>{},
    );
    final existing = _maps(account['tasks'])
        .map((task) => '${task['task_name'] ?? ''}'.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    final searchController = TextEditingController();
    var keyword = '';
    final selected = <String>{};
    final selectedTasks = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final normalized = keyword.trim().toLowerCase();
          final filtered = catalog.where((task) {
            final name = '${task['task_name'] ?? ''}'.toLowerCase();
            final display = '${task['task_display_name'] ?? name}'
                .toLowerCase();
            return normalized.isEmpty ||
                name.contains(normalized) ||
                display.contains(normalized);
          }).toList();
          return AlertDialog(
            title: Text('添加任务'.tr),
            content: SizedBox(
              width: 520,
              height: 560,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: '搜索所有任务',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setDialogState(() => keyword = value),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        final taskName = '${task['task_name'] ?? ''}'.trim();
                        final displayName =
                            '${task['task_display_name'] ?? taskName}'.trim();
                        final alreadyAdded = existing.contains(taskName);
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: alreadyAdded || selected.contains(taskName),
                          title: Text(displayName),
                          subtitle: alreadyAdded ? const Text('已添加') : null,
                          onChanged: alreadyAdded || taskName.isEmpty
                              ? null
                              : (checked) => setDialogState(() {
                                  if (checked == true) {
                                    selected.add(taskName);
                                  } else {
                                    selected.remove(taskName);
                                  }
                                }),
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
                child: Text('取消'.tr),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.of(dialogContext).pop(selected.toList()),
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
    searchController.dispose();
    if (selectedTasks == null || selectedTasks.isEmpty) return;
    for (final taskName in selectedTasks) {
      final ok = await ApiClient().addMultiAccountRepeatNewFixedTask(
        scriptName: widget.scriptName,
        accountIndex: accountIndex,
        taskName: taskName,
      );
      if (!ok) return;
    }
    _reload();
  }

  Future<void> _deleteTask(int accountIndex, String taskName) async {
    final confirmed = await _confirm('删除任务'.tr, '删除后会同时清除该账号任务的私有配置，是否继续？'.tr);
    if (confirmed != true) return;
    if (await ApiClient().deleteMultiAccountRepeatNewFixedTask(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
    )) {
      _reload();
    }
  }

  Future<void> _showPublicSettings() async {
    final data = await ApiClient().getMultiAccountRepeatNewFixedPublicArgs(
      scriptName: widget.scriptName,
    );
    if (!mounted || data.isEmpty) return;
    final args = Get.find<ArgsController>();
    await args.loadGroupsFromData(
      config: widget.scriptName,
      task: 'MultiAccountRepeatNewFixed',
      json: data,
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) {
        return ApiClient().putMultiAccountRepeatNewFixedPublicArg(
          scriptName: config,
          groupName: group,
          argumentName: argument,
          type: type,
          value: value,
        );
      },
    );
    if (!mounted) return;
    await _showArgsDialog(args, '多账号多任务新固定时间公共配置'.tr);
  }

  Future<void> _showTaskSettings(
    int accountIndex,
    String taskName,
    String taskDisplayName,
  ) async {
    setState(() => _loadingTasks.add(taskName));
    final data = await ApiClient().getMultiAccountRepeatNewFixedTaskArgs(
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
        return ApiClient().putMultiAccountRepeatNewFixedTaskArg(
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
                            .resetMultiAccountRepeatNewFixedTaskPrivateConfig(
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
        .copyMultiAccountRepeatNewFixedTaskPrivateConfig(
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
                  taskName: 'MultiAccountRepeatNewFixed',
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

  void _reload() {
    if (!mounted) return;
    setState(() {
      _stateFuture = ApiClient().getMultiAccountRepeatNewFixedAccounts(
        scriptName: widget.scriptName,
      );
    });
  }
}
