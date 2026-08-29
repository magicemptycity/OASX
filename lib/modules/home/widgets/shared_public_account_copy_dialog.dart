import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/translation/i18n_content.dart';

/// 在公共账号库中选择账号，并复制到一个或多个其他脚本实例。
Future<bool> showSharedPublicAccountCopyDialog({
  required BuildContext context,
  required String sourceScriptName,
  required List<Map<String, dynamic>> accounts,
}) async {
  final sourceAccounts = accounts.where((account) {
    return '${account['identifier'] ?? ''}'.trim().isNotEmpty;
  }).toList();
  if (sourceAccounts.isEmpty) {
    Get.snackbar(I18n.tip.tr, '暂无可复制的公共账号');
    return false;
  }

  final scripts = (await ApiClient().getScriptList())
      .where((name) => name != sourceScriptName && name != 'template')
      .toList();
  if (!context.mounted) return false;
  if (scripts.isEmpty) {
    Get.snackbar(I18n.tip.tr, '没有其他脚本实例可复制');
    return false;
  }

  final selectedIdentifiers = <String>{};
  final selectedScripts = <String>{};
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final allAccountsSelected =
            selectedIdentifiers.length == sourceAccounts.length;
        final allScriptsSelected = selectedScripts.length == scripts.length;
        return AlertDialog(
          title: const Text('复制公共账号到其他脚本'),
          content: SizedBox(
            width: 820,
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('仅复制所选账号信息；不会复制运行账号、任务、私有配置、调度和运行记录。目标脚本存在同账号标识时，将更新该账号信息。'),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _CopySelectionPanel(
                          title: '选择账号信息',
                          allSelected: allAccountsSelected,
                          onSelectAll: () => setDialogState(() {
                            if (allAccountsSelected) {
                              selectedIdentifiers.clear();
                            } else {
                              selectedIdentifiers.addAll(
                                sourceAccounts.map(
                                  (account) => '${account['identifier']}',
                                ),
                              );
                            }
                          }),
                          child: ListView.separated(
                            itemCount: sourceAccounts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final account = sourceAccounts[index];
                              final identifier = '${account['identifier']}';
                              return CheckboxListTile(
                                value: selectedIdentifiers.contains(identifier),
                                onChanged: (value) => setDialogState(() {
                                  if (value == true) {
                                    selectedIdentifiers.add(identifier);
                                  } else {
                                    selectedIdentifiers.remove(identifier);
                                  }
                                }),
                                title: Text(identifier),
                                subtitle: Text(_accountDetail(account)),
                                isThreeLine: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _CopySelectionPanel(
                          title: '选择目标脚本',
                          allSelected: allScriptsSelected,
                          onSelectAll: () => setDialogState(() {
                            if (allScriptsSelected) {
                              selectedScripts.clear();
                            } else {
                              selectedScripts.addAll(scripts);
                            }
                          }),
                          child: ListView.separated(
                            itemCount: scripts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final scriptName = scripts[index];
                              return CheckboxListTile(
                                value: selectedScripts.contains(scriptName),
                                onChanged: (value) => setDialogState(() {
                                  if (value == true) {
                                    selectedScripts.add(scriptName);
                                  } else {
                                    selectedScripts.remove(scriptName);
                                  }
                                }),
                                title: Text(scriptName),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton.icon(
              onPressed:
                  selectedIdentifiers.isEmpty || selectedScripts.isEmpty
                  ? null
                  : () async {
                      final success = await ApiClient()
                          .copyMultiAccountSharedAccounts(
                            sourceScriptName: sourceScriptName,
                            identifiers: selectedIdentifiers.toList(),
                            targetScriptNames: selectedScripts.toList(),
                          );
                      if (!dialogContext.mounted) return;
                      if (success) {
                        Get.snackbar(
                          I18n.success.tr,
                          '已复制${selectedIdentifiers.length}个账号到${selectedScripts.length}个脚本',
                        );
                        Navigator.of(dialogContext).pop(true);
                      }
                    },
              icon: const Icon(Icons.content_copy_rounded),
              label: Text('复制'.tr),
            ),
          ],
        );
      },
    ),
  );
  return result == true;
}

String _accountDetail(Map<String, dynamic> account) {
  final character = '${account['character'] ?? ''}'.trim();
  final server = '${account['svr'] ?? ''}'.trim();
  final login = '${account['account'] ?? ''}'.trim();
  final platform = account['apple_or_android'] == false ? '苹果' : '安卓';
  String value(String text) => text.isEmpty ? '-' : text;
  return '角色：${value(character)} · 服务器：${value(server)}\n'
      '账号：${value(login)} · 平台：$platform';
}

class _CopySelectionPanel extends StatelessWidget {
  const _CopySelectionPanel({
    required this.title,
    required this.allSelected,
    required this.onSelectAll,
    required this.child,
  });

  final String title;
  final bool allSelected;
  final VoidCallback onSelectAll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
            child: Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
                TextButton.icon(
                  onPressed: onSelectAll,
                  icon: Icon(
                    allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 18,
                  ),
                  label: Text(allSelected ? '取消全选' : '全选'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: child)),
        ],
      ),
    );
  }
}
