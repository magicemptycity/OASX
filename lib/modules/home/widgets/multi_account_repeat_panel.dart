import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/translation/i18n_content.dart';

/// 多账号多任务的账号级任务编辑器。
class MultiAccountRepeatPanel extends StatefulWidget {
  const MultiAccountRepeatPanel({
    super.key,
    required this.scriptName,
    required this.repeatTaskName,
    required this.onBack,
  });

  final String scriptName;
  final String repeatTaskName;
  final Future<void> Function() onBack;

  @override
  State<MultiAccountRepeatPanel> createState() =>
      _MultiAccountRepeatPanelState();
}

class _MultiAccountRepeatPanelState extends State<MultiAccountRepeatPanel> {
  late Future<Map<String, dynamic>> _stateFuture;
  late final Future<Map<String, List<String>>> _menuFuture;
  int _selectedAccount = 1;
  final Set<String> _loadingTasks = <String>{};

  @override
  void initState() {
    super.initState();
    _stateFuture = ApiClient().getMultiAccountRepeatAccounts(
      scriptName: widget.scriptName,
      repeatTaskName: widget.repeatTaskName,
    );
    _menuFuture = ApiClient().getScriptMenu();
  }

  @override
  void didUpdateWidget(covariant MultiAccountRepeatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptName == widget.scriptName &&
        oldWidget.repeatTaskName == widget.repeatTaskName) {
      return;
    }
    _selectedAccount = 1;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _stateFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? const <String, dynamic>{};
        final rawAccounts = data['accounts'];
        final accounts = rawAccounts is List
            ? rawAccounts
                  .whereType<Map>()
                  .map((item) => item.cast<String, dynamic>())
                  .toList()
            : <Map<String, dynamic>>[];
        if (accounts.isEmpty) {
          return Center(child: Text(I18n.taskNotFound.tr));
        }
        if (_selectedAccount > accounts.length) {
          _selectedAccount = accounts.length;
        }
        final account = accounts[_selectedAccount - 1];
        final rawTasks = account['tasks'];
        final tasks = rawTasks is List
            ? rawTasks
                  .whereType<Map>()
                  .map((item) => item.cast<String, dynamic>())
                  .toList()
            : <Map<String, dynamic>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountSelector(context, accounts),
            const SizedBox(height: 12),
            Expanded(child: _buildTaskList(context, account, tasks)),
          ],
        );
      },
    );
  }

  Widget _buildAccountSelector(
    BuildContext context,
    List<Map<String, dynamic>> accounts,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final account in accounts) ...[
                ChoiceChip(
                  label: Text(_accountLabel(account)),
                  selected: account['index'] == _selectedAccount,
                  onSelected: (_) {
                    final index = account['index'];
                    if (index is int) {
                      setState(() => _selectedAccount = index);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    Map<String, dynamic> account,
    List<Map<String, dynamic>> tasks,
  ) {
    return Card(
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
                FilledButton.icon(
                  onPressed: _showAddTaskDialog,
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
                    final hasPrivate = task['has_private_config'] == true;
                    final loading = _loadingTasks.contains(taskName);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        hasPrivate
                            ? Icons.person_pin_rounded
                            : Icons.public_rounded,
                      ),
                      title: Text(taskName.tr),
                      subtitle: Text(hasPrivate ? '使用账号私有配置'.tr : '使用公共配置'.tr),
                      trailing: Wrap(
                        spacing: 2,
                        children: [
                          IconButton(
                            tooltip: '设置私有配置'.tr,
                            onPressed: loading || taskName.isEmpty
                                ? null
                                : () => _showTaskSettings(taskName),
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
                                : () => _deleteTask(taskName),
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

  String _accountLabel(Map<String, dynamic> account) {
    final character = '${account['character'] ?? ''}'.trim();
    final server = '${account['svr'] ?? ''}'.trim();
    final index = account['index'] ?? '';
    final name = [character, server].where((item) => item.isNotEmpty).join('-');
    return name.isEmpty ? '账号 $index' : '账号 $index：$name';
  }

  Future<void> _showAddTaskDialog() async {
    final menu = await _menuFuture;
    if (!mounted) {
      return;
    }
    final taskNames = <String>[];
    for (final entry in menu.entries) {
      for (final taskName in entry.value) {
        final name = taskName.trim();
        if (name.isEmpty || name == 'Script' || name == 'Restart') {
          continue;
        }
        if (name.startsWith('MultiAccount') || taskNames.contains(name)) {
          continue;
        }
        taskNames.add(name);
      }
    }
    taskNames.sort((left, right) => left.tr.compareTo(right.tr));
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('选择要添加的功能'.tr),
        content: SizedBox(
          width: 420,
          height: 520,
          child: ListView.builder(
            itemCount: taskNames.length,
            itemBuilder: (context, index) {
              final taskName = taskNames[index];
              return ListTile(
                title: Text(taskName.tr),
                onTap: () => Navigator.of(dialogContext).pop(taskName),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(I18n.cancel.tr),
          ),
        ],
      ),
    );
    if (selected == null) {
      return;
    }
    final ret = await ApiClient().addMultiAccountRepeatTask(
      scriptName: widget.scriptName,
      repeatTaskName: widget.repeatTaskName,
      accountIndex: _selectedAccount,
      taskName: selected,
    );
    if (ret) {
      _reload();
    }
  }

  Future<void> _deleteTask(String taskName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('删除任务'.tr),
        content: Text('删除后会同时清除该账号的私有配置，是否继续？'.tr),
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
    if (confirmed != true) {
      return;
    }
    final ret = await ApiClient().deleteMultiAccountRepeatTask(
      scriptName: widget.scriptName,
      repeatTaskName: widget.repeatTaskName,
      accountIndex: _selectedAccount,
      taskName: taskName,
    );
    if (ret) {
      _reload();
    }
  }

  Future<void> _showTaskSettings(String taskName) async {
    setState(() => _loadingTasks.add(taskName));
    final data = await ApiClient().getMultiAccountRepeatTaskArgs(
      scriptName: widget.scriptName,
      repeatTaskName: widget.repeatTaskName,
      accountIndex: _selectedAccount,
      taskName: taskName,
    );
    if (!mounted || data.isEmpty) {
      if (mounted) {
        setState(() => _loadingTasks.remove(taskName));
      }
      return;
    }
    final argsController = Get.find<ArgsController>();
    await argsController.loadGroupsFromData(
      config: widget.scriptName,
      task: taskName,
      json: data,
      stagingMode: true,
      saveArgumentOverride: (config, task, group, argument, type, value) {
        return ApiClient().putMultiAccountRepeatTaskArg(
          scriptName: config,
          repeatTaskName: widget.repeatTaskName,
          accountIndex: _selectedAccount,
          taskName: task,
          groupName: group,
          argumentName: argument,
          type: type,
          value: value,
        );
      },
    );
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 720,
          height: 680,
          child: Column(
            children: [
              ListTile(
                title: Text('${taskName.tr}：${'账号私有配置'.tr}'),
                trailing: IconButton(
                  tooltip: '关闭'.tr,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Expanded(
                child: Args(
                  scriptName: widget.scriptName,
                  taskName: taskName,
                  stagingMode: true,
                  onCancel: () async {
                    await argsController.discardDraftChanges();
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ),
              TextButton(
                onPressed: () async {
                  final ret = await ApiClient()
                      .clearMultiAccountRepeatTaskPrivateConfig(
                        scriptName: widget.scriptName,
                        repeatTaskName: widget.repeatTaskName,
                        accountIndex: _selectedAccount,
                        taskName: taskName,
                      );
                  if (ret && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text('恢复公共配置'.tr),
              ),
            ],
          ),
        ),
      ),
    );
    await argsController.discardDraftChanges();
    if (mounted) {
      setState(() => _loadingTasks.remove(taskName));
      _reload();
    }
  }

  void _reload() {
    if (!mounted) {
      return;
    }
    setState(() {
      _stateFuture = ApiClient().getMultiAccountRepeatAccounts(
        scriptName: widget.scriptName,
        repeatTaskName: widget.repeatTaskName,
      );
    });
  }
}
