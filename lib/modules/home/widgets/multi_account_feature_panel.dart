import 'package:flutter/material.dart';

import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/multi_account_kekkai_utilize_new_panel.dart';
import 'package:oasx/modules/home/widgets/multi_account_repeat_fixed_panel.dart';
import 'package:oasx/modules/home/widgets/multi_account_repeat_normal_panel.dart';
import 'package:oasx/modules/home/widgets/multi_account_repeat_timed_panel.dart';
import 'package:oasx/modules/home/widgets/multi_account_task_orchestration_panel.dart';
import 'package:oasx/modules/home/widgets/task_parameter_panel.dart';

typedef MultiAccountFeatureBuilder =
    Widget Function({
      required HomeDashboardController controller,
      required ScriptModel scriptModel,
      required Future<void> Function() onBack,
    });

class MultiAccountFeatureDefinition {
  const MultiAccountFeatureDefinition({
    required this.taskName,
    required this.key,
    required this.mode,
    required this.builder,
  });

  final String taskName;
  final String key;
  final String mode;
  final MultiAccountFeatureBuilder builder;
}

/// 新多账号功能注册表。
///
/// 新增同类功能时只需在这里注册页面、能力类型和后端 key，任务目录不再
/// 继续堆叠功能判断；各功能原有配置和接口仍由对应面板负责，保持兼容。
const multiAccountFeatureDefinitions = <MultiAccountFeatureDefinition>[
  MultiAccountFeatureDefinition(
    taskName: 'MultiAccountTaskOrchestration',
    key: 'multi_account_task_orchestration',
    mode: 'orchestration',
    builder: _buildTaskOrchestration,
  ),
  MultiAccountFeatureDefinition(
    taskName: 'MultiAccountRepeatNewNormal',
    key: 'multi_account_repeat_new_normal',
    mode: 'normal',
    builder: _buildRepeatNewNormal,
  ),
  MultiAccountFeatureDefinition(
    taskName: 'MultiAccountRepeatNewFixed',
    key: 'multi_account_repeat_new_fixed',
    mode: 'fixed_group',
    builder: _buildRepeatNewFixed,
  ),
  MultiAccountFeatureDefinition(
    taskName: 'MultiAccountRepeatTimed',
    key: 'multi_account_repeat_timed',
    mode: 'timed',
    builder: _buildRepeatTimed,
  ),
  MultiAccountFeatureDefinition(
    taskName: 'MultiAccountKekkaiUtilizeNew',
    key: 'multi_account_kekkai_utilize_new',
    mode: 'account_scheduler',
    builder: _buildKekkaiUtilizeNew,
  ),
];

Widget _buildTaskOrchestration({
  required controller,
  required scriptModel,
  required onBack,
}) => MultiAccountTaskOrchestrationPanel(
  controller: controller,
  scriptModel: scriptModel,
  onBack: onBack,
);
Widget _buildRepeatNewNormal({
  required controller,
  required scriptModel,
  required onBack,
}) => MultiAccountRepeatNewNormalPanel(
  controller: controller,
  scriptModel: scriptModel,
  onBack: onBack,
);
Widget _buildRepeatNewFixed({
  required controller,
  required scriptModel,
  required onBack,
}) => MultiAccountRepeatNewFixedPanel(
  controller: controller,
  scriptModel: scriptModel,
  onBack: onBack,
);
Widget _buildRepeatTimed({
  required controller,
  required scriptModel,
  required onBack,
}) => MultiAccountRepeatTimedPanel(
  controller: controller,
  scriptModel: scriptModel,
  onBack: onBack,
);
Widget _buildKekkaiUtilizeNew({
  required controller,
  required scriptModel,
  required onBack,
}) => MultiAccountKekkaiUtilizeNewPanel(
  controller: controller,
  scriptModel: scriptModel,
  onBack: onBack,
);

/// 新多账号功能的统一页面入口，未注册的任务继续使用原通用参数页。
class MultiAccountFeaturePanel extends StatelessWidget {
  const MultiAccountFeaturePanel({
    super.key,
    required this.taskName,
    required this.controller,
    required this.scriptModel,
    required this.onBack,
  });

  final String taskName;
  final HomeDashboardController controller;
  final ScriptModel scriptModel;
  final Future<void> Function() onBack;

  @override
  Widget build(BuildContext context) {
    final definition = multiAccountFeatureDefinitions
        .where((item) => item.taskName == taskName)
        .firstOrNull;
    return (definition?.builder ?? _buildDefault)(
      controller: controller,
      scriptModel: scriptModel,
      onBack: onBack,
    );
  }
}

Widget _buildDefault({
  required controller,
  required scriptModel,
  required onBack,
}) => TaskParameterPanel(
  controller: controller,
  scriptModel: scriptModel,
  onBack: onBack,
);
