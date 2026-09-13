import 'package:flutter/material.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/multi_account_feature_descriptor.dart';
import 'package:oasx/modules/home/widgets/multi_account_repeat_fixed_panel.dart';
import 'package:oasx/modules/home/widgets/multi_account_repeat_normal_panel.dart';
import 'package:oasx/modules/home/widgets/multi_account_repeat_timed_panel.dart';
import 'package:oasx/modules/home/widgets/multi_account_scheduler_feature_panel.dart';
import 'package:oasx/modules/home/widgets/multi_account_task_orchestration_panel.dart';
import 'package:oasx/modules/home/widgets/task_parameter_panel.dart';

/// 新多账号功能统一入口。全部新功能从 OAS manifest 动态发现并按 mode
/// 选择通用页面；复制同类型功能时不再修改 OASX。
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

  Widget _defaultPanel() => TaskParameterPanel(
    controller: controller,
    scriptModel: scriptModel,
    onBack: onBack,
  );

  Widget _buildFeature(MultiAccountFeatureDescriptor feature) {
    switch (feature.mode) {
      case 'account_scheduler':
        return MultiAccountSchedulerFeaturePanel(
          controller: controller,
          scriptModel: scriptModel,
          onBack: onBack,
          feature: feature,
        );
      case 'normal':
      case 'task_list':
        return MultiAccountRepeatNewNormalPanel(
          controller: controller,
          scriptModel: scriptModel,
          onBack: onBack,
          feature: feature,
        );
      case 'timed':
        return MultiAccountRepeatTimedPanel(
          controller: controller,
          scriptModel: scriptModel,
          onBack: onBack,
          feature: feature,
        );
      case 'fixed_group':
      case 'fixed_batches':
        return MultiAccountRepeatNewFixedPanel(
          controller: controller,
          scriptModel: scriptModel,
          onBack: onBack,
          feature: feature,
        );
      case 'orchestration':
        return MultiAccountTaskOrchestrationPanel(
          controller: controller,
          scriptModel: scriptModel,
          onBack: onBack,
          feature: feature,
        );
      default:
        return _defaultPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!taskName.startsWith('MultiAccount')) return _defaultPanel();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiClient().getMultiAccountFeatures(scriptModel.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final raw = snapshot.data
            ?.where(
              (item) =>
                  item['task_name'] == taskName && item['available'] != false,
            )
            .firstOrNull;
        if (raw == null) return _defaultPanel();
        return _buildFeature(MultiAccountFeatureDescriptor.fromJson(raw));
      },
    );
  }
}
