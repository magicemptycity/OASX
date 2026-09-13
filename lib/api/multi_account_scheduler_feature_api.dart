part of 'api_client.dart';

/// 动态的新多账号账号调度 API。路径和可选能力均由 OAS manifest 提供。
class MultiAccountSchedulerFeatureApi {
  MultiAccountSchedulerFeatureApi(this.feature, {ApiClient? client})
    : client = client ?? ApiClient();

  final MultiAccountFeatureDescriptor feature;
  final ApiClient client;
  String get _base => feature.apiPrefix;
  String get _settingsPath => feature.settingsPath ?? 'settings-args';

  Future<Map<String, dynamic>> getAccounts({required String scriptName}) async {
    final res = await client.request(() => get('/$scriptName/$_base/accounts'));
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getPublicAccounts({
    required String scriptName,
  }) async {
    final res = await client.request(
      () => get('/$scriptName/$_base/public-accounts'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addAccount({
    required String scriptName,
    required String identifier,
  }) async {
    final res = await client.request(
      () => post(
        '/$scriptName/$_base/accounts',
        queryParameters: {'public_account_identifier': identifier},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteAccount({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await client.request(
      () => delete('/$scriptName/$_base/accounts/$accountIndex'),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getPublicArgs({
    required String scriptName,
  }) async {
    final res = await client.request(
      () => get('/$scriptName/$_base/public-args'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putPublicArg({
    required String scriptName,
    required String groupName,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await client.request(
      () => put(
        '/$scriptName/$_base/public-args/$groupName/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getSchedulerArgs({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await client.request(
      () => get('/$scriptName/$_base/accounts/$accountIndex/scheduler-args'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putSchedulerArg({
    required String scriptName,
    required int accountIndex,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await client.request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/scheduler-args/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> quickScheduleAccount({
    required String scriptName,
    required int accountIndex,
    required bool runNow,
  }) async {
    final res = await client.request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/quick-schedule',
        queryParameters: {'run_now': runNow},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setAccountScheduleEnabled({
    required String scriptName,
    required int accountIndex,
    required bool enable,
  }) async {
    final res = await client.request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/enable',
        queryParameters: {'value': enable},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getSettingsArgs({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await client.request(
      () => get('/$scriptName/$_base/accounts/$accountIndex/$_settingsPath'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> putSettingsArg({
    required String scriptName,
    required int accountIndex,
    required String argumentName,
    required String type,
    required dynamic value,
  }) async {
    final res = await client.request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/$_settingsPath/$argumentName/value',
        queryParameters: {'types': type, 'value': value},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> resetSettingsArgs({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await client.request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/$_settingsPath/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copySettingsArgs({
    required String scriptName,
    required int accountIndex,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await client.request(
      () => post(
        '/$scriptName/$_base/accounts/$accountIndex/$_settingsPath/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, dynamic>> getForbidPeriods({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await client.request(
      () => get('/$scriptName/$_base/accounts/$accountIndex/forbid-periods'),
    );
    return res.isSuccess && res.data is Map
        ? (res.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<bool> addForbidPeriod({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await client.request(
      () => post('/$scriptName/$_base/accounts/$accountIndex/forbid-periods'),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> updateForbidPeriod({
    required String scriptName,
    required int accountIndex,
    required int periodIndex,
    required String start,
    required String end,
  }) async {
    final res = await client.request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/forbid-periods/$periodIndex',
        queryParameters: {'start': start, 'end': end},
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> deleteForbidPeriod({
    required String scriptName,
    required int accountIndex,
    required int periodIndex,
  }) async {
    final res = await client.request(
      () => delete(
        '/$scriptName/$_base/accounts/$accountIndex/forbid-periods/$periodIndex',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> resetForbidPeriods({
    required String scriptName,
    required int accountIndex,
  }) async {
    final res = await client.request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/forbid-periods/default',
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> copyForbidPeriods({
    required String scriptName,
    required int accountIndex,
    required List<int> targetAccountIndexes,
  }) async {
    if (targetAccountIndexes.isEmpty) return false;
    final res = await client.request(
      () => post(
        '/$scriptName/$_base/accounts/$accountIndex/forbid-periods/copy',
        queryParameters: {
          'target_account_indexes': targetAccountIndexes.join(','),
        },
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<bool> setAccountLocalEnabled({
    required String scriptName,
    required int accountIndex,
    required bool enabled,
  }) async {
    final res = await client.request(
      () => put(
        '/$scriptName/$_base/accounts/$accountIndex/account-enable',
        queryParameters: {'enable': enabled},
      ),
    );
    return res.isSuccess && res.data == true;
  }
}
