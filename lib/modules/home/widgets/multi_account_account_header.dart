import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/home/widgets/account_management_dialogs.dart';

/// 新多账号功能共用的账号操作栏；业务页面只提供回调和账号选择器。
class MultiAccountAccountHeader extends StatelessWidget {
  const MultiAccountAccountHeader({
    super.key,
    this.accountSelector,
    this.extraActions = const <Widget>[],
    required this.onPublicAccounts,
    required this.onPublicSettings,
    required this.onAddAccount,
    this.onToggleAccount,
    this.onDeleteAccounts,
    this.accountEnabled = true,
  });

  final Widget? accountSelector;
  final List<Widget> extraActions;
  final VoidCallback onPublicAccounts;
  final VoidCallback onPublicSettings;
  final VoidCallback onAddAccount;
  final VoidCallback? onToggleAccount;
  final VoidCallback? onDeleteAccounts;
  final bool accountEnabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer.withValues(alpha: 0.24),
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
                  onPressed: onPublicAccounts,
                  icon: Icons.groups_rounded,
                  label: '公共账号库'.tr,
                ),
                buildAccountManagementButton(
                  onPressed: onPublicSettings,
                  icon: Icons.settings_rounded,
                  label: '公共配置'.tr,
                ),
                buildAccountManagementButton(
                  onPressed: onAddAccount,
                  icon: Icons.person_add_alt_1_rounded,
                  label: '添加账号'.tr,
                  filled: true,
                ),
                if (onToggleAccount != null)
                  buildAccountManagementButton(
                    onPressed: onToggleAccount!,
                    icon: accountEnabled
                        ? Icons.power_settings_new_rounded
                        : Icons.power_off_rounded,
                    label: accountEnabled ? '停用当前账号'.tr : '启用当前账号'.tr,
                  ),
                if (onDeleteAccounts != null)
                  buildAccountManagementButton(
                    onPressed: onDeleteAccounts!,
                    icon: Icons.person_remove_outlined,
                    label: '删除账号'.tr,
                  ),
                ...extraActions,
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 10),
            Text('运行账号'.tr, style: Theme.of(context).textTheme.labelLarge),
            if (accountSelector != null) ...[
              const SizedBox(height: 6),
              accountSelector!,
            ],
          ],
        ),
      ),
    );
  }
}
