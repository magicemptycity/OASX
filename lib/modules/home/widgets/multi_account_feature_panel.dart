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
  static final Map<String, Future<List<Map<String, dynamic>>>> _featureCache =
      {};
  static final Map<String, DateTime> _featureCacheTime = {};
  static const Duration _featureCacheTtl = Duration(seconds: 30);

  static Future<List<Map<String, dynamic>>> _features(String scriptName) {
    final cachedAt = _featureCacheTime[scriptName];
    if (cachedAt == null ||
        DateTime.now().difference(cachedAt) > _featureCacheTtl) {
      _featureCacheTime[scriptName] = DateTime.now();
      _featureCache[scriptName] = ApiClient().getMultiAccountFeatures(
        scriptName,
      );
    }
    return _featureCache[scriptName]!;
  }

  /// 配置模型刷新或后端重启后可主动清除此实例的发现缓存。
  static void invalidateFeatureCache([String? scriptName]) {
    if (scriptName == null) {
      _featureCache.clear();
      _featureCacheTime.clear();
    } else {
      _featureCache.remove(scriptName);
      _featureCacheTime.remove(scriptName);
    }
  }

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
          key: ValueKey(feature.key),
          controller: controller,
          scriptModel: scriptModel,
          onBack: onBack,
          feature: feature,
        );
      case 'normal':
      case 'task_list':
        return MultiAccountRepeatNewNormalPanel(
          key: ValueKey(feature.key),
          controller: controller,
          scriptModel: scriptModel,
          onBack: onBack,
          feature: feature,
        );
      case 'timed':
        return MultiAccountRepeatTimedPanel(
          key: ValueKey(feature.key),
          controller: controller,
          scriptModel: scriptModel,
          onBack: onBack,
          feature: feature,
        );
      case 'fixed_group':
      case 'fixed_batches':
        return MultiAccountRepeatNewFixedPanel(
          key: ValueKey(feature.key),
          controller: controller,
          scriptModel: scriptModel,
          onBack: onBack,
          feature: feature,
        );
      case 'orchestration':
        return MultiAccountTaskOrchestrationPanel(
          key: ValueKey(feature.key),
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
      future: _features(scriptModel.name),
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
        final feature = MultiAccountFeatureDescriptor.fromJson(raw);
        if (feature.protocolVersion != 1) {
          return Center(
            child: Text('不支持的多账号页面协议版本：${feature.protocolVersion}'),
          );
        }
        return _buildFeature(feature);
      },
    );
  }
}
