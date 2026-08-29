import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_json_transfer_actions.dart';
import 'package:oasx/modules/home/widgets/shared_public_account_copy_dialog.dart';
import 'package:oasx/translation/i18n_content.dart';

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
  final Set<String> _loadingTasks = <String>{};

  @override
  void initState() {
    super.initState();
    _stateFuture = ApiClient().getMultiAccountRepeatTimedAccounts(
      scriptName: widget.scriptName,
    );
    _menuFuture = ApiClient().getScriptMenu();
  }

  @override
  void didUpdateWidget(covariant MultiAccountRepeatTimedPanel oldWidget) {
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
                  onPressed: () => _showAddTaskDialog(accountIndex),
                  icon: const Icon(Icons.add_rounded),
                  label: Text('添加任务'.tr),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              // 定时任务列表至少容纳十项；超过十项后只滚动该列表。
              height: _taskListBodyHeight(),
              child: tasks.isEmpty
                  ? Center(child: Text('当前账号尚未添加任务'.tr))
                  : ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final taskName = '${task['task_name'] ?? ''}'.trim();
                        final taskDisplayName =
                            '${task['task_display_name'] ?? taskName}'.trim();
                        final status = '${task['status'] ?? 'pending'}';
                        final nextRun = '${task['next_run'] ?? ''}'.trim();
                        final loading = _loadingTasks.contains(taskName);
                        return ListTile(
                          isThreeLine: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _taskStatusIcon(status),
                            color: _taskStatusColor(context, status),
                          ),
                          title: Text(taskDisplayName),
                          subtitle: Text(
                            "${_taskStatusLabel(status)}\n"
                            '下次运行：${nextRun.isEmpty ? '-' : nextRun}',
                          ),
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

  double _taskListBodyHeight() => 10 * 88.0;

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
      'completed' => '已完成'.tr,
      'failed' => '运行失败'.tr,
      'unfinished' => '未完成'.tr,
      _ => '待运行'.tr,
    };
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
    final data = await ApiClient().getMultiAccountRepeatTimedPublicAccounts(
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
                                  .deleteMultiAccountRepeatTimedPublicAccount(
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
          ),          TextButton.icon(
            onPressed: () async {
              final identifier = await _askText('新增公共账号'.tr, '账号标识'.tr);
              if (identifier == null || identifier.trim().isEmpty) return;
              final ok = await ApiClient()
                  .addMultiAccountRepeatTimedPublicAccount(
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
    if (await ApiClient().addMultiAccountRepeatTimedAccount(
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
    if (await ApiClient().deleteMultiAccountRepeatTimedAccount(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
    )) {
      _selectedAccount = 1;
      _reload();
    }
  }

  Future<void> _showAddTaskDialog(int accountIndex) async {
    final menu = await _menuFuture;
    if (!mounted) return;
    final names = <String>[];
    for (final group in menu.values) {
      for (final task in group) {
        final name = task.trim();
        if (name.isEmpty ||
            name == 'Script' ||
            name == 'Restart' ||
            name == 'GlobalGame' ||
            name.startsWith('MultiAccount')) {
          continue;
        }
        if (!names.contains(name)) names.add(name);
      }
    }
    names.sort((a, b) => a.tr.compareTo(b.tr));
    final searchController = TextEditingController();
    String keyword = '';
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final normalizedKeyword = keyword.trim().toLowerCase();
          final filteredNames = names.where((name) {
            if (normalizedKeyword.isEmpty) return true;
            return name.toLowerCase().contains(normalizedKeyword) ||
                name.tr.toLowerCase().contains(normalizedKeyword);
          }).toList();
          return AlertDialog(
            title: Text('选择要添加的功能'.tr),
            content: SizedBox(
              width: 460,
              height: 560,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: '搜索任务',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setDialogState(() => keyword = value),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredNames.isEmpty
                        ? const Center(child: Text('未找到匹配任务'))
                        : ListView.builder(
                            itemCount: filteredNames.length,
                            itemBuilder: (context, index) => ListTile(
                              title: Text(filteredNames[index].tr),
                              onTap: () => Navigator.of(
                                dialogContext,
                              ).pop(filteredNames[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    searchController.dispose();
    if (selected == null) return;
    if (await ApiClient().addMultiAccountRepeatTimedTask(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: selected,
    )) {
      _reload();
    }
  }

  Future<void> _deleteTask(int accountIndex, String taskName) async {
    final confirmed = await _confirm('删除任务'.tr, '删除后会同时清除该账号任务的私有配置，是否继续？'.tr);
    if (confirmed != true) return;
    if (await ApiClient().deleteMultiAccountRepeatTimedTask(
      scriptName: widget.scriptName,
      accountIndex: accountIndex,
      taskName: taskName,
    )) {
      _reload();
    }
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

  void _reload() {
    if (!mounted) return;
    setState(() {
      _stateFuture = ApiClient().getMultiAccountRepeatTimedAccounts(
        scriptName: widget.scriptName,
      );
    });
  }
}
