class MultiAccountFeatureDescriptor {
  const MultiAccountFeatureDescriptor({
    required this.key,
    required this.taskName,
    required this.displayName,
    required this.mode,
    required this.apiPrefix,
    this.settingsPath,
    this.settingsGroup,
    this.nextRunField,
    this.forbidPeriods = false,
    this.taskList = false,
    this.fixedBatches = false,
    this.orchestration = false,
    this.overviewKind,
  });

  final String key;
  final String taskName;
  final String displayName;
  final String mode;
  final String apiPrefix;
  final String? settingsPath;
  final String? settingsGroup;
  final String? nextRunField;
  final bool forbidPeriods;
  final bool taskList;
  final bool fixedBatches;
  final bool orchestration;
  final String? overviewKind;

  factory MultiAccountFeatureDescriptor.fromJson(Map<String, dynamic> json) {
    final capabilities = json['capabilities'] is Map
        ? (json['capabilities'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return MultiAccountFeatureDescriptor(
      key: '${json['key'] ?? ''}',
      taskName: '${json['task_name'] ?? ''}',
      displayName: '${json['name'] ?? json['task_name'] ?? ''}',
      mode: '${json['mode'] ?? ''}',
      apiPrefix: '${json['api_prefix'] ?? json['key'] ?? ''}',
      settingsPath: json['settings_path']?.toString(),
      settingsGroup: json['settings_group']?.toString(),
      nextRunField: json['next_run_field']?.toString(),
      forbidPeriods:
          capabilities['forbid_periods'] == true ||
          json['forbid_periods'] == true,
      taskList: capabilities['task_list'] == true || json['task_list'] == true,
      fixedBatches:
          capabilities['fixed_batches'] == true ||
          json['fixed_batches'] == true,
      orchestration:
          capabilities['orchestration'] == true ||
          json['orchestration'] == true,
    );
  }
}
