part of 'api_client.dart';

extension ApiClientScriptX on ApiClient {
  /// Loads the full argument model for one task.
  Future<Map<String, dynamic>> getScriptTask(
    String scriptName,
    String taskName,
  ) async {
    final res = await request(() => get('/$scriptName/$taskName/args'));
    return res.data ?? {};
  }

  /// Persists one task argument through the generic value endpoint.
  Future<bool> putScriptArg(
    String scriptName,
    String taskName,
    String groupName,
    String argumentName,
    String type,
    dynamic value,
  ) async {
    final res = await request(
      () => put(
        '/$scriptName/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  /// Synchronizes one task back into the waiting queue immediately.
  Future<bool> syncScriptTaskNextRun(
    String scriptName,
    String taskName,
    String targetDt,
  ) async {
    final res = await request(
      () => put(
        '/$scriptName/$taskName/sync_next_run',
        queryParameters: {'target_dt': targetDt},
      ),
    );
    return res.isSuccess && res.data == true;
  }
}

/// 多账号多任务新专属接口；不调用旧多账号多任务的任何路由。
extension ApiClientMultiAccountRepeatNewNormalX on ApiClient {
  Future<Map<String, dynamic>> getMultiAccountRepeatNewNormalPublicAccounts({
    required String scriptName,
  }) async {
    final res = await request(() => get('/$scriptName/shared-accounts'));
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addMultiAccountRepeatNewNormalPublicAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/shared-accounts',
        queryParameters: {'identifier': identifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> putMultiAccountRepeatNewNormalPublicAccountValue({
    required String scriptName,
    required String identifier,
    required String field,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/shared-accounts/$identifier/$field/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewNormalPublicAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => delete('/$scriptName/shared-accounts/$identifier'),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewNormalAccounts({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_new_normal/accounts'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addMultiAccountRepeatNewNormalAccount({
    required String scriptName,
    required String publicAccountIdentifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_normal/accounts',
        queryParameters: {'public_account_identifier': publicAccountIdentifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewNormalAccount({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountRepeatNewNormalTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewNormalTaskEnable({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required bool enable,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/tasks/$taskName/enable',
        queryParameters: {'value': enable},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> reorderMultiAccountRepeatNewNormalTasks({
    required String scriptName,
    required int accountIndex,
    required List<String> taskNames,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/tasks/order',
        queryParameters: {'task_names': taskNames.join('\n')},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewNormalTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewNormalTaskStatus({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required String status,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/tasks/$taskName/status',
        queryParameters: {'value': status},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewNormalTaskProgress({
    required String scriptName,
    required int accountIndex,
    required String completedTaskList,
    required String failedTaskList,
    required String unfinishedTaskList,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/task-progress',
        queryParameters: {
          'completed_task_list': completedTaskList,
          'failed_task_list': failedTaskList,
          'unfinished_task_list': unfinishedTaskList,
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewNormalLastCompleteTime({
    required String scriptName,
    required int accountIndex,
    required String value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/last-complete-time',
        queryParameters: {'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> rerunMultiAccountRepeatNewNormalAccount({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/rerun',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewNormalPublicArgs({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_new_normal/public-args'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewNormalPublicArg({
    required String scriptName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/public-args/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewNormalTaskArgs({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewNormalTaskArg({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyMultiAccountRepeatNewNormalTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/tasks/$taskName/private/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> resetMultiAccountRepeatNewNormalTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/tasks/$taskName/private/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }
}

/// 多账号多任务定时专属接口；不调用旧多账号多任务的任何路由。
/// 多账号多任务新固定时间专属接口；不调用旧多账号多任务的任何路由。
extension ApiClientMultiAccountRepeatNewFixedX on ApiClient {
  Future<Map<String, dynamic>> getMultiAccountRepeatNewFixedPublicAccounts({
    required String scriptName,
  }) async {
    final res = await request(() => get('/$scriptName/shared-accounts'));
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addMultiAccountRepeatNewFixedPublicAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/shared-accounts',
        queryParameters: {'identifier': identifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> putMultiAccountRepeatNewFixedPublicAccountValue({
    required String scriptName,
    required String identifier,
    required String field,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/shared-accounts/$identifier/$field/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewFixedPublicAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => delete('/$scriptName/shared-accounts/$identifier'),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewFixedAccounts({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_new_fixed/accounts'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>>
  getMultiAccountRepeatNewFixedFixedTimeTasks({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_new_fixed/fixed-time-tasks'),
    );
    if (!res.isSuccess || res.data is! Map) return <Map<String, dynamic>>[];
    final tasks = (res.data as Map)['tasks'];
    return tasks is List
        ? tasks
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];
  }

  Future<bool> addMultiAccountRepeatNewFixedFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String name,
    String? runTime,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches',
        queryParameters: {
          'name': name,
          if (runTime != null) 'run_time': runTime,
        },
      ),
    );
    return res.isSuccess;
  }

  Future<bool> deleteMultiAccountRepeatNewFixedFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String batchId,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyMultiAccountRepeatNewFixedFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewFixedFixedTimeBatchEnable({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required bool enable,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/enable',
        queryParameters: {'value': enable},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewFixedFixedTimeBatchRunTime({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String runTime,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/run-time',
        queryParameters: {'value': runTime},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewFixedFixedTimeBatchSchedule({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String runTime,
    required String scheduleMode,
    required int intervalDays,
    required List<int> weekdays,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/schedule',
        queryParameters: {
          'run_time': runTime,
          'schedule_mode': scheduleMode,
          'interval_days': intervalDays,
          'weekdays': weekdays.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>>
  getMultiAccountRepeatNewFixedFixedTimeBatchSchedulerArgs({
    required String scriptName,
    required int accountIndex,
    required String batchId,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/scheduler/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewFixedFixedTimeBatchSchedulerArg({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/scheduler/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> quickScheduleMultiAccountRepeatNewFixedSpecialTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required bool runNow,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/quick-schedule',
        queryParameters: {'run_now': runNow.toString()},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> rerunMultiAccountRepeatNewFixedSpecialTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/rerun',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewFixedSpecialTaskLastCompleteTime({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/last-complete-time',
        queryParameters: {'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> reorderMultiAccountRepeatNewFixedSpecialTaskTasks({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required List<String> taskNames,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/order',
        queryParameters: {'task_names': taskNames.join('\n')},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewFixedSpecialTaskTaskStatus({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
    required String status,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/status',
        queryParameters: {'value': status},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountRepeatNewFixedFixedTimeBatchTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewFixedFixedTimeBatchTaskEnable({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
    required bool enable,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/enable',
        queryParameters: {'value': enable},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewFixedFixedTimeBatchTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>>
  getMultiAccountRepeatNewFixedFixedTimeBatchTaskArgs({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewFixedFixedTimeBatchTaskArg({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool>
  resetMultiAccountRepeatNewFixedFixedTimeBatchTaskPrivateConfigToDefault({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/private/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountRepeatNewFixedAccount({
    required String scriptName,
    required String publicAccountIdentifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_fixed/accounts',
        queryParameters: {'public_account_identifier': publicAccountIdentifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewFixedAccount({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountRepeatNewFixedTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewFixedTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewFixedPublicArgs({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_new_fixed/public-args'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewFixedPublicArg({
    required String scriptName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/public-args/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewFixedTaskArgs({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewFixedTaskArg({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyMultiAccountRepeatNewFixedTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/tasks/$taskName/private/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> resetMultiAccountRepeatNewFixedTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/tasks/$taskName/private/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }
}

/// 多账号任务编排专属接口：账号下多个原生 Scheduler 的顺序任务组。
/// 通用公共账号库跨脚本复制。
extension ApiClientMultiAccountSharedAccountsX on ApiClient {
  Future<bool> copyMultiAccountSharedAccounts({
    required String sourceScriptName,
    required List<String> identifiers,
    required List<String> targetScriptNames,
  }) async {
    if (identifiers.isEmpty || targetScriptNames.isEmpty) return false;
    final res = await request(
      () => post(
        '/$sourceScriptName/shared-accounts/copy',
        queryParameters: {
          'identifiers': identifiers.join(','),
          'target_script_names': targetScriptNames.join(','),
        },
      ),
    );
    return res.isSuccess;
  }
}

extension ApiClientMultiAccountTaskOrchestrationX on ApiClient {
  Future<Map<String, dynamic>> getMultiAccountTaskOrchestrationPublicAccounts({
    required String scriptName,
  }) async {
    final res = await request(() => get('/$scriptName/shared-accounts'));
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addMultiAccountTaskOrchestrationPublicAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/shared-accounts',
        queryParameters: {'identifier': identifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> putMultiAccountTaskOrchestrationPublicAccountValue({
    required String scriptName,
    required String identifier,
    required String field,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/shared-accounts/$identifier/$field/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountTaskOrchestrationPublicAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => delete('/$scriptName/shared-accounts/$identifier'),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountTaskOrchestrationAccounts({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_task_orchestration/accounts'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>>
  getMultiAccountTaskOrchestrationFixedTimeTasks({
    required String scriptName,
  }) async {
    final res = await request(
      () =>
          get('/$scriptName/multi_account_task_orchestration/fixed-time-tasks'),
    );
    if (!res.isSuccess || res.data is! Map) return <Map<String, dynamic>>[];
    final tasks = (res.data as Map)['tasks'];
    return tasks is List
        ? tasks
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];
  }

  Future<bool> addMultiAccountTaskOrchestrationFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String name,
    String? runTime,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches',
        queryParameters: {
          'name': name,
          if (runTime != null) 'run_time': runTime,
        },
      ),
    );
    return res.isSuccess;
  }

  Future<bool> deleteMultiAccountTaskOrchestrationFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String batchId,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyMultiAccountTaskOrchestrationFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await request(
      () => post(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountTaskOrchestrationFixedTimeBatchEnable({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required bool enable,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/enable',
        queryParameters: {'value': enable},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountTaskOrchestrationFixedTimeBatchRunTime({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String runTime,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/run-time',
        queryParameters: {'value': runTime},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountTaskOrchestrationFixedTimeBatchSchedule({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String runTime,
    required String scheduleMode,
    required int intervalDays,
    required List<int> weekdays,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/schedule',
        queryParameters: {
          'run_time': runTime,
          'schedule_mode': scheduleMode,
          'interval_days': intervalDays,
          'weekdays': weekdays.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>>
  getMultiAccountTaskOrchestrationFixedTimeBatchSchedulerArgs({
    required String scriptName,
    required int accountIndex,
    required String batchId,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/scheduler/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountTaskOrchestrationFixedTimeBatchSchedulerArg({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/scheduler/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> quickScheduleMultiAccountTaskOrchestrationSpecialTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required bool runNow,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/quick-schedule',
        queryParameters: {'run_now': runNow.toString()},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> rerunMultiAccountTaskOrchestrationSpecialTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/rerun',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountTaskOrchestrationSpecialTaskLastCompleteTime({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/last-complete-time',
        queryParameters: {'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> reorderMultiAccountTaskOrchestrationSpecialTaskTasks({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required List<String> taskNames,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/order',
        queryParameters: {'task_names': taskNames.join('\n')},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountTaskOrchestrationSpecialTaskTaskStatus({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
    required String status,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/status',
        queryParameters: {'value': status},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountTaskOrchestrationFixedTimeBatchTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountTaskOrchestrationFixedTimeBatchTaskEnable({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
    required bool enable,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/enable',
        queryParameters: {'value': enable},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountTaskOrchestrationFixedTimeBatchTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>>
  getMultiAccountTaskOrchestrationFixedTimeBatchTaskArgs({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountTaskOrchestrationFixedTimeBatchTaskArg({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool>
  resetMultiAccountTaskOrchestrationFixedTimeBatchTaskPrivateConfigToDefault({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/private/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountTaskOrchestrationAccount({
    required String scriptName,
    required String publicAccountIdentifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_task_orchestration/accounts',
        queryParameters: {'public_account_identifier': publicAccountIdentifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountTaskOrchestrationAccount({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountTaskOrchestrationTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountTaskOrchestrationSingleTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/single-tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess;
  }

  Future<bool> quickScheduleMultiAccountTaskOrchestrationSingleTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required bool runNow,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/single-tasks/$taskName/quick-schedule',
        queryParameters: {'run_now': runNow.toString()},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountTaskOrchestrationTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountTaskOrchestrationPublicArgs({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_task_orchestration/public-args'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountTaskOrchestrationPublicArg({
    required String scriptName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/public-args/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountTaskOrchestrationTaskArgs({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountTaskOrchestrationTaskArg({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyMultiAccountTaskOrchestrationTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await request(
      () => post(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/tasks/$taskName/private/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> resetMultiAccountTaskOrchestrationTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_task_orchestration/accounts/$accountIndex/tasks/$taskName/private/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }
}

/// 多账号多任务定时专属接口；不调用旧多账号多任务的任何路由。
extension ApiClientMultiAccountRepeatTimedX on ApiClient {
  Future<Map<String, dynamic>> getMultiAccountRepeatTimedPublicAccounts({
    required String scriptName,
  }) async {
    final res = await request(() => get('/$scriptName/shared-accounts'));
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addMultiAccountRepeatTimedPublicAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/shared-accounts',
        queryParameters: {'identifier': identifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> putMultiAccountRepeatTimedPublicAccountValue({
    required String scriptName,
    required String identifier,
    required String field,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/shared-accounts/$identifier/$field/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatTimedPublicAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => delete('/$scriptName/shared-accounts/$identifier'),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatTimedAccounts({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_timed/accounts'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addMultiAccountRepeatTimedAccount({
    required String scriptName,
    required String publicAccountIdentifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_timed/accounts',
        queryParameters: {'public_account_identifier': publicAccountIdentifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatTimedAccount({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_timed/accounts/$accountIndex',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountRepeatTimedTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_timed/accounts/$accountIndex/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatTimedTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_timed/accounts/$accountIndex/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> quickScheduleMultiAccountRepeatTimedTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required bool runNow,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_timed/accounts/$accountIndex/tasks/$taskName/quick-schedule',
        queryParameters: {'run_now': runNow.toString()},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatTimedTaskEnable({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required bool enable,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_timed/accounts/$accountIndex/tasks/$taskName/enable',
        queryParameters: {'value': enable.toString()},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatTimedPublicArgs({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_timed/public-args'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatTimedPublicArg({
    required String scriptName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_timed/public-args/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatTimedTaskArgs({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_repeat_timed/accounts/$accountIndex/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatTimedTaskArg({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_timed/accounts/$accountIndex/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyMultiAccountRepeatTimedTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_timed/accounts/$accountIndex/tasks/$taskName/private/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> resetMultiAccountRepeatTimedTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_timed/accounts/$accountIndex/tasks/$taskName/private/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }
}

/// 多账号多任务蹭卡新专属接口。
extension ApiClientMultiAccountKekkaiUtilizeNewX on ApiClient {
  static const _base = 'multi_account_kekkai_utilize_new';

  Future<Map<String, dynamic>> getMultiAccountKekkaiUtilizeNewAccounts({
    required String scriptName,
  }) async {
    final res = await request(() => get('/$scriptName/$_base/accounts'));
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getMultiAccountKekkaiUtilizeNewPublicAccounts({
    required String scriptName,
  }) async {
    final res = await request(() => get('/$scriptName/$_base/public-accounts'));
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addMultiAccountKekkaiUtilizeNewAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/$_base/accounts',
        queryParameters: {'public_account_identifier': identifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountKekkaiUtilizeNewAccount({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => delete('/$scriptName/$_base/accounts/$accountIndex'),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountKekkaiUtilizeNewPublicArgs({
    required String scriptName,
  }) async {
    final res = await request(() => get('/$scriptName/$_base/public-args'));
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountKekkaiUtilizeNewPublicArg({
    required String scriptName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/$_base/public-args/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountKekkaiUtilizeNewSchedulerArgs({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => get('/$scriptName/$_base/accounts/$accountIndex/scheduler-args'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountKekkaiUtilizeNewSchedulerArg({
    required String scriptName,
    required int accountIndex,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/scheduler-args/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> quickScheduleMultiAccountKekkaiUtilizeNewAccount({
    required String scriptName,
    required int accountIndex,
    required bool runNow,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/quick-schedule',
        queryParameters: {'run_now': runNow},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountKekkaiUtilizeNewAccountEnable({
    required String scriptName,
    required int accountIndex,
    required bool enable,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/enable',
        queryParameters: {'value': enable},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountKekkaiUtilizeNewUtilizeArgs({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => get('/$scriptName/$_base/accounts/$accountIndex/utilize-args'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountKekkaiUtilizeNewUtilizeArg({
    required String scriptName,
    required int accountIndex,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/utilize-args/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> resetMultiAccountKekkaiUtilizeNewUtilizeArgs({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/utilize-args/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyMultiAccountKekkaiUtilizeNewUtilizeArgs({
    required String scriptName,
    required int accountIndex,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await request(
      () => post(
        '/$scriptName/$_base/accounts/$accountIndex/utilize-args/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountKekkaiUtilizeNewForbidPeriods({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => get('/$scriptName/$_base/accounts/$accountIndex/forbid-periods'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addMultiAccountKekkaiUtilizeNewForbidPeriod({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => post('/$scriptName/$_base/accounts/$accountIndex/forbid-periods'),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> updateMultiAccountKekkaiUtilizeNewForbidPeriod({
    required String scriptName,
    required int accountIndex,
    required int periodIndex,
    required String start,
    required String end,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/forbid-periods/$periodIndex',
        queryParameters: {'start': start, 'end': end},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountKekkaiUtilizeNewForbidPeriod({
    required String scriptName,
    required int accountIndex,
    required int periodIndex,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/$_base/accounts/$accountIndex/forbid-periods/$periodIndex',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> resetMultiAccountKekkaiUtilizeNewForbidPeriods({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/forbid-periods/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyMultiAccountKekkaiUtilizeNewForbidPeriods({
    required String scriptName,
    required int accountIndex,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await request(
      () => post(
        '/$scriptName/$_base/accounts/$accountIndex/forbid-periods/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }
}
