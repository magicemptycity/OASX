import 'package:flutter/material.dart';

/// OAS 主任务页使用的分类卡外壳。
///
/// 所有需要“任务”分类页的地方都使用此组件，确保圆角、边框、标题高度、展开内容
/// 和分隔线完全一致。
class TaskCatalogSectionCard extends StatelessWidget {
  const TaskCatalogSectionCard({
    super.key,
    required this.header,
    required this.children,
    required this.expanded,
    required this.forceExpanded,
    required this.onToggleExpanded,
    this.highlighted = false,
  });

  final Widget header;
  final List<Widget> children;
  final bool expanded;
  final bool forceExpanded;
  final VoidCallback onToggleExpanded;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final effectiveExpanded = forceExpanded || expanded;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: highlighted
          ? scheme.primaryContainer.withValues(alpha: 0.35)
          : effectiveExpanded
          ? Theme.of(context).cardColor
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: forceExpanded ? null : onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: header),
                  const SizedBox(width: 10),
                  Icon(
                    effectiveExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (effectiveExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }
}
