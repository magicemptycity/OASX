import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/common/models/config_drag_payload.dart';
import 'package:oasx/modules/common/widgets/drag_copy_feedback.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/widgets/split_scroll_row.dart';
import 'package:oasx/modules/home/widgets/task_status_swipe_container.dart';
import 'package:oasx/translation/i18n_content.dart';

part 'task_status_row_parts.dart';

/// Describes one task row rendered inside the overview task list.
class TaskStatusViewData {
  const TaskStatusViewData({
    required this.rowId,
    required this.name,
    required this.type,
    this.timeText = '',
    this.timeEditable = true,
    this.displayName,
  });

  final String rowId;
  final String name;
  final TaskStatusType type;
  final String timeText;
  final bool timeEditable;
  final String? displayName;
}

/// Defines the three task states rendered in the overview tab.
enum TaskStatusType { running, pending, waiting }

/// Shared OAS overview-card shell used by task and account lists.
class TaskOverviewRow extends StatelessWidget {
  const TaskOverviewRow({
    super.key,
    required this.type,
    required this.leading,
    required this.trailing,
    this.trailingExtent = 132,
    this.swipeEnabled = false,
    this.onConfirmDismiss,
    this.onDismissed,
    this.highlighted = false,
  });

  final TaskStatusType type;
  final Widget leading;
  final Widget trailing;
  final double trailingExtent;
  final bool swipeEnabled;
  final Future<bool> Function()? onConfirmDismiss;
  final VoidCallback? onDismissed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final rowBackground = TaskOverviewCard.backgroundColor(context, type);
    return TaskOverviewCard(
      type: type,
      swipeEnabled: swipeEnabled,
      onConfirmDismiss: onConfirmDismiss,
      onDismissed: onDismissed,
      highlighted: highlighted,
      child: SplitScrollRow(
        minHeight: 40,
        trailingExtent: trailingExtent,
        trailingBackgroundColor: rowBackground,
        trailing: trailing,
        leading: leading,
      ),
    );
  }
}

/// Shared OAS overview-card container.
///
/// Use this when a feature needs the exact overview card surface, padding and
/// state colors but has its own inner layout instead of a task action row.
class TaskOverviewCard extends StatelessWidget {
  const TaskOverviewCard({
    super.key,
    required this.type,
    required this.child,
    this.swipeEnabled = false,
    this.onConfirmDismiss,
    this.onDismissed,
    this.highlighted = false,
  });

  final TaskStatusType type;
  final Widget child;
  final bool swipeEnabled;
  final Future<bool> Function()? onConfirmDismiss;
  final VoidCallback? onDismissed;
  final bool highlighted;

  static Color backgroundColor(BuildContext context, TaskStatusType type) {
    final scheme = Theme.of(context).colorScheme;
    return switch (type) {
      TaskStatusType.running => scheme.tertiaryContainer.withValues(
        alpha: 0.24,
      ),
      TaskStatusType.pending => scheme.secondaryContainer.withValues(
        alpha: 0.2,
      ),
      TaskStatusType.waiting => scheme.surfaceContainerHigh,
    };
  }

  static Color borderColor(BuildContext context, TaskStatusType type) {
    final scheme = Theme.of(context).colorScheme;
    return switch (type) {
      TaskStatusType.running => Colors.green.withValues(alpha: 0.28),
      TaskStatusType.pending => Colors.orange.withValues(alpha: 0.3),
      TaskStatusType.waiting => scheme.outlineVariant.withValues(alpha: 0.7),
    };
  }

  @override
  Widget build(BuildContext context) {
    final background = backgroundColor(context, type);
    return TaskStatusSwipeContainer(
      enabled: swipeEnabled && onConfirmDismiss != null,
      onConfirmDismiss: onConfirmDismiss ?? () async => false,
      onDismissed: onDismissed ?? () {},
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highlighted
              ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.42)
              : background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor(context, type)),
        ),
        child: Padding(padding: const EdgeInsets.all(10), child: child),
      ),
    );
  }
}

/// Renders one swipe-to-disable task row for the overview tab.
class TaskStatusRow extends StatelessWidget {
  const TaskStatusRow({
    super.key,
    required this.controller,
    required this.sourceScriptName,
    required this.task,
    required this.canQuickSchedule,
    required this.quickScheduleLocked,
    this.showQuickActions = true,
    this.leadingActions = const [],
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
    required this.onDisableTask,
    required this.onDismissed,
    required this.dragEnabled,
    required this.swipeEnabled,
    required this.activeDragPayload,
  });

  final HomeDashboardController controller;
  final String sourceScriptName;
  final TaskStatusViewData task;
  final bool canQuickSchedule;
  final bool quickScheduleLocked;

  /// Some account task types intentionally have no per-task scheduler.
  final bool showQuickActions;

  /// Feature-specific actions rendered immediately before quick-run actions.
  final List<Widget> leadingActions;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;
  final Future<bool> Function(String taskName) onDisableTask;
  final ValueChanged<String> onDismissed;
  final bool dragEnabled;
  final bool swipeEnabled;
  final ConfigDragPayload? activeDragPayload;
  static const double _actionExtent = 132;

  @override
  Widget build(BuildContext context) {
    final isDraggingTask =
        activeDragPayload?.matchesTask(sourceScriptName, task.name) ?? false;
    return TaskOverviewRow(
      type: task.type,
      swipeEnabled: swipeEnabled,
      onConfirmDismiss: () => onDisableTask(task.name),
      onDismissed: () => onDismissed(task.rowId),
      highlighted: isDraggingTask,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TaskStatusTypeIcon(type: task.type),
          const SizedBox(width: 10),
          _TaskMeta(
            controller: controller,
            sourceScriptName: sourceScriptName,
            task: task,
            onSetNextRun: onSetNextRun,
            dragEnabled: dragEnabled,
          ),
        ],
      ),
      trailing: _TaskActionBar(
        onQuickRun: showQuickActions && !quickScheduleLocked && canQuickSchedule
            ? () => onQuickRun(task.name)
            : null,
        onQuickWait:
            showQuickActions && !quickScheduleLocked && canQuickSchedule
            ? () => onQuickWait(task.name)
            : null,
        showQuickActions: showQuickActions,
        leadingActions: leadingActions,
        onEditTask: () => onEditTask(task.name),
      ),
      trailingExtent: _actionExtent + leadingActions.length * 40,
    );
  }
}
