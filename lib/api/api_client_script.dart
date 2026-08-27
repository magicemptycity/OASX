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

/// 多账号多任务的账号级任务配置接口。
extension ApiClientMultiAccountRepeatX on ApiClient {
  Future<Map<String, dynamic>> getMultiAccountRepeatAccounts({
    required String scriptName,
    required String repeatTaskName,
  }) async {
    final res = await request(
      () => get('/$scriptName/multi_account_repeat/$repeatTaskName/accounts'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addMultiAccountRepeatTask({
    required String scriptName,
    required String repeatTaskName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => post(
        '/$scriptName/multi_account_repeat/$repeatTaskName/accounts/$accountIndex/tasks',
        queryParameters: {'task_name': taskName},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteMultiAccountRepeatTask({
    required String scriptName,
    required String repeatTaskName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat/$repeatTaskName/accounts/$accountIndex/tasks/$taskName',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getMultiAccountRepeatTaskArgs({
    required String scriptName,
    required String repeatTaskName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => get(
        '/$scriptName/multi_account_repeat/$repeatTaskName/accounts/$accountIndex/tasks/$taskName/args',
      ),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putMultiAccountRepeatTaskArg({
    required String scriptName,
    required String repeatTaskName,
    required int accountIndex,
    required String taskName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await request(
      () => put(
        '/$scriptName/multi_account_repeat/$repeatTaskName/accounts/$accountIndex/tasks/$taskName/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> clearMultiAccountRepeatTaskPrivateConfig({
    required String scriptName,
    required String repeatTaskName,
    required int accountIndex,
    required String taskName,
  }) async {
    final res = await request(
      () => delete(
        '/$scriptName/multi_account_repeat/$repeatTaskName/accounts/$accountIndex/tasks/$taskName/private',
      ),
    );
    return res.isSuccess && res.data == true;
  }
}
