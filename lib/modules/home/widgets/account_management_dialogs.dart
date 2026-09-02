import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/translation/i18n_content.dart';

typedef AccountMap = Map<String, dynamic>;
typedef AccountDetailBuilder = String Function(AccountMap account);

/// Builds an account-management action as an icon with a hover tooltip.
Widget buildAccountManagementButton({
  required VoidCallback? onPressed,
  required IconData icon,
  required String label,
  bool filled = false,
}) {
  if (filled) {
    return IconButton.filled(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
  return IconButton(
    tooltip: label,
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
  );
}

/// Shared account-management dialogs used by every new multi-account task.
///
/// Keeping these dialogs here makes new multi-account panels inherit the same
/// selection, deletion, and public-library behavior automatically.
Future<List<String>?> showMultiAccountPickerDialog({
  required BuildContext context,
  required List<AccountMap> choices,
  required AccountDetailBuilder detailBuilder,
}) async {
  var keyword = '';
  final selected = <String>{};
  final searchController = TextEditingController();
  final result = await showDialog<List<String>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final query = keyword.trim().toLowerCase();
        final visibleChoices = choices.where((account) {
          final identifier = '${account['identifier'] ?? ''}';
          return query.isEmpty ||
              '$identifier ${detailBuilder(account)}'.toLowerCase().contains(
                query,
              );
        }).toList();
        return AlertDialog(
          title: Text('选择运行账号'.tr),
          content: SizedBox(
            width: 520,
            height: 500,
            child: choices.isEmpty
                ? Center(child: Text('没有可添加的公共账号'.tr))
                : Column(
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          hintText: '搜索账号、角色名或服务器'.tr,
                        ),
                        onChanged: (value) =>
                            setDialogState(() => keyword = value),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: visibleChoices.isEmpty
                            ? Center(child: Text('未找到匹配账号'.tr))
                            : ListView.builder(
                                itemCount: visibleChoices.length,
                                itemBuilder: (context, index) {
                                  final account = visibleChoices[index];
                                  final identifier =
                                      '${account['identifier'] ?? ''}';
                                  return CheckboxListTile(
                                    value: selected.contains(identifier),
                                    title: Text(identifier),
                                    subtitle: Text(detailBuilder(account)),
                                    isThreeLine: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (value) => setDialogState(() {
                                      if (value == true) {
                                        selected.add(identifier);
                                      } else {
                                        selected.remove(identifier);
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
              child: Text(I18n.cancel.tr),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(selected.toList()),
              child: Text('${'添加'.tr}（${selected.length}）'),
            ),
          ],
        );
      },
    ),
  );
  searchController.dispose();
  return result;
}

/// Shows the common batch-delete picker. The caller performs the actual API calls.
Future<List<int>?> showBatchAccountDeleteDialog({
  required BuildContext context,
  required List<AccountMap> accounts,
  required AccountDetailBuilder titleBuilder,
  required AccountDetailBuilder detailBuilder,
}) async {
  final selected = <int>{};
  return showDialog<List<int>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('批量删除运行账号'.tr),
        content: SizedBox(
          width: 520,
          height: 420,
          child: ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              final accountIndex = account['index'] as int? ?? index + 1;
              return CheckboxListTile(
                value: selected.contains(accountIndex),
                title: Text(titleBuilder(account)),
                subtitle: Text(detailBuilder(account)),
                isThreeLine: true,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) => setDialogState(() {
                  if (value == true) {
                    selected.add(accountIndex);
                  } else {
                    selected.remove(accountIndex);
                  }
                }),
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
            onPressed: selected.isEmpty
                ? null
                : () => Navigator.of(dialogContext).pop(selected.toList()),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text('${'删除'.tr}（${selected.length}）'),
          ),
        ],
      ),
    ),
  );
}

/// Shared public-account-library dialog. Delete/edit/add all refresh in place.
Future<void> showPublicAccountLibraryDialog({
  required BuildContext context,
  required Future<List<AccountMap>> Function() loadAccounts,
  required Future<bool> Function(String identifier) onDelete,
  required Future<bool> Function(AccountMap account) onEdit,
  required Future<bool> Function() onAdd,
  required AccountDetailBuilder detailBuilder,
  Future<bool> Function(List<AccountMap> accounts)? onCopy,
}) async {
  var accounts = await loadAccounts();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('公共账号库'.tr),
        content: SizedBox(
          width: 620,
          height: 480,
          child: accounts.isEmpty
              ? Center(child: Text('暂无公共账号'.tr))
              : ListView.separated(
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final identifier = '${account['identifier'] ?? ''}';
                    return ListTile(
                      title: Text(identifier),
                      subtitle: Text(detailBuilder(account)),
                      isThreeLine: true,
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: '设置'.tr,
                            onPressed: () async {
                              if (!await onEdit(account) ||
                                  !dialogContext.mounted) {
                                return;
                              }
                              final refreshed = await loadAccounts();
                              if (dialogContext.mounted) {
                                setDialogState(() => accounts = refreshed);
                              }
                            },
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            tooltip: '删除'.tr,
                            onPressed: () async {
                              if (!await onDelete(identifier) ||
                                  !dialogContext.mounted) {
                                return;
                              }
                              setDialogState(() {
                                accounts = List<AccountMap>.from(accounts)
                                  ..removeAt(index);
                              });
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
          if (onCopy != null)
            TextButton.icon(
              onPressed: accounts.isEmpty
                  ? null
                  : () async {
                      if (await onCopy(accounts) && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
              icon: const Icon(Icons.content_copy_rounded),
              label: const Text('复制到其他脚本'),
            ),
          TextButton.icon(
            onPressed: () async {
              if (!await onAdd() || !dialogContext.mounted) return;
              final refreshed = await loadAccounts();
              if (dialogContext.mounted) {
                setDialogState(() => accounts = refreshed);
              }
            },
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text('新增公共账号'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('关闭'.tr),
          ),
        ],
      ),
    ),
  );
}
