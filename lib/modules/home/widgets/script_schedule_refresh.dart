import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/config_model.dart';

/// Subscribes to the same scheduler snapshot stream used by OAS overview.
///
/// Each WebSocket `schedule` push replaces [ScriptModel.waitingTaskList] after
/// the running and pending fields. Listening to it therefore observes a fully
/// updated native schedule snapshot without adding polling or parallel state.
Worker bindNativeScheduleRefresh(
  ScriptModel scriptModel,
  VoidCallback onScheduleUpdated,
) => ever(scriptModel.waitingTaskList, (_) => onScheduleUpdated());
