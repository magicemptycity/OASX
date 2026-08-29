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
extension ApiClientMultiAccountRepeatNewX on ApiClient {
  Future<Map<String, dynamic>> getMultiAccountRepeatNewPublicAccounts({
    required String scriptName,
  }) async {
    final res = await request(() => get('/$scriptName/shared-accounts'));
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

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
  Future<bool> addMultiAccountRepeatNewPublicAccount({
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

  Future<bool> putMultiAccountRepeatNewPublicAccountValue({
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

  Future<bool> deleteMultiAccountRepeatNewPublicAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await request(
      () => delete('/$scriptName/shared-accounts/$identifier'),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewAccounts({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_new/accounts'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getMultiAccountRepeatNewFixedTimeTasks({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_new/fixed-time-tasks'),
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

  Future<bool> addMultiAccountRepeatNewFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String runTime,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/fixed-time-batches',
        queryParameters: {'run_time': runTime},
      ),
    );
    return res.isSuccess;
  }

  Future<bool> deleteMultiAccountRepeatNewFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String batchId,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/fixed-time-batches/$batchId',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewFixedTimeBatchEnable({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required bool enable,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/fixed-time-batches/$batchId/enable',
        queryParameters: {'value': enable},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewFixedTimeBatchRunTime({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String runTime,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/fixed-time-batches/$batchId/run-time',
        queryParameters: {'value': runTime},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountRepeatNewFixedTimeBatchTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/fixed-time-batches/$batchId/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewFixedTimeBatchTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewFixedTimeBatchTaskArgs({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewFixedTimeBatchTaskArg({
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
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool>
  resetMultiAccountRepeatNewFixedTimeBatchTaskPrivateConfigToDefault({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/private/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountRepeatNewAccount({
    required String scriptName,
    required String publicAccountIdentifier,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new/accounts',
        queryParameters: {'public_account_identifier': publicAccountIdentifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewAccount({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountRepeatNewTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewTask({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewPublicArgs({
    required String scriptName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat_new/public-args'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewPublicArg({
    required String scriptName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new/public-args/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatNewTaskArgs({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewTaskArg({
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
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyMultiAccountRepeatNewTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/tasks/$taskName/private/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> resetMultiAccountRepeatNewTaskPrivateConfig({
    required String scriptName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new/accounts/$accountIndex/tasks/$taskName/private/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }
}

/// 多账号多任务定时专属接口；不调用旧多账号多任务的任何路由。
/// 多账号多任务新普通专属接口；不调用旧多账号多任务的任何路由。
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

  Future<List<Map<String, dynamic>>>
  getMultiAccountRepeatNewNormalFixedTimeTasks({
    required String scriptName,
  }) async {
    final res = await request(
      () =>
          get('/$scriptName/multi_account_repeat_new_normal/fixed-time-tasks'),
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

  Future<bool> addMultiAccountRepeatNewNormalFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String runTime,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/fixed-time-batches',
        queryParameters: {'run_time': runTime},
      ),
    );
    return res.isSuccess;
  }

  Future<bool> deleteMultiAccountRepeatNewNormalFixedTimeBatch({
    required String scriptName,
    required int accountIndex,
    required String batchId,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/fixed-time-batches/$batchId',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewNormalFixedTimeBatchEnable({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required bool enable,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/fixed-time-batches/$batchId/enable',
        queryParameters: {'value': enable},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setMultiAccountRepeatNewNormalFixedTimeBatchRunTime({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String runTime,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/fixed-time-batches/$batchId/run-time',
        queryParameters: {'value': runTime},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> addMultiAccountRepeatNewNormalFixedTimeBatchTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/fixed-time-batches/$batchId/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatNewNormalFixedTimeBatchTask({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>>
  getMultiAccountRepeatNewNormalFixedTimeBatchTaskArgs({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatNewNormalFixedTimeBatchTaskArg({
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
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool>
  resetMultiAccountRepeatNewNormalFixedTimeBatchTaskPrivateConfigToDefault({
    required String scriptName,
    required int accountIndex,
    required String batchId,
    required String taskName,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat_new_normal/accounts/$accountIndex/fixed-time-batches/$batchId/tasks/$taskName/private/default',
      ),
    );
    return res.isSuccess && res.data == true;
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
    required String runTime,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat_new_fixed/accounts/$accountIndex/fixed-time-batches',
        queryParameters: {'run_time': runTime},
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
