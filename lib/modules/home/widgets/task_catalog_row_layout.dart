import 'package:flutter/material.dart';
import 'package:oasx/modules/home/widgets/split_scroll_row.dart';

/// OAS 原生任务目录的单行布局。
///
/// 主任务页与多账号任务页共用，避免启用图标、任务名称和右侧操作区出现偏移。
class TaskCatalogSplitRow extends StatelessWidget {
  const TaskCatalogSplitRow({
    super.key,
    required this.scrollKey,
    required this.taskLabel,
    required this.supportsEnable,
    required this.enabled,
    required this.loading,
    required this.onToggleEnabled,
    required this.trailing,
    this.trailingExtent = 132.0,
  });

  final Key scrollKey;
  final Widget taskLabel;
  final bool supportsEnable;
  final bool enabled;
  final bool loading;
  final ValueChanged<bool>? onToggleEnabled;
  final Widget trailing;
  final double trailingExtent;

  @override
  Widget build(BuildContext context) {
    final rowBackground = Theme.of(
      context,
    ).colorScheme.secondaryContainer.withValues(alpha: 0.18);
    return SplitScrollRow(
      scrollKey: scrollKey,
      minHeight: 40,
      trailingExtent: trailingExtent,
      trailingBackgroundColor: rowBackground,
      trailing: trailing,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (supportsEnable)
            TaskCatalogEnableIcon(
              enabled: enabled,
              loading: loading,
              onTap: onToggleEnabled,
            )
          else
            const SizedBox(width: 22, height: 22),
          const SizedBox(width: 10),
          taskLabel,
        ],
      ),
    );
  }
}

/// OAS 原生任务启用圆形图标。
class TaskCatalogEnableIcon extends StatelessWidget {
  const TaskCatalogEnableIcon({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final ValueChanged<bool>? onTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap == null ? null : () => onTap!(!enabled),
      child: Icon(
        enabled
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
        size: 22,
      ),
    );
  }
}

/// OAS 原生任务行右侧图标按钮。
class TaskCatalogIconOnlyButton extends StatelessWidget {
  const TaskCatalogIconOnlyButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}
