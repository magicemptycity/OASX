import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/translation/i18n_content.dart';

/// 多账号功能共用的“启用任务”选择弹窗。
///
/// 调用方负责提供已按 OAS 原生菜单顺序排好的任务，以及提交启用请求。
enum _EnableTaskFilter { all, enabled, disabled }

Future<List<String>?> showMultiAccountEnableTasksDialog({
  required BuildContext context,
  required String title,
  required Future<List<String>> taskNamesFuture,
  required bool Function(String taskName) isTaskEnabled,
}) async {
  final searchController = TextEditingController();
  final selectedTaskNames = <String>{};
  var searchQuery = '';
  var filter = _EnableTaskFilter.all;
  try {
    return await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 620,
            height: 620,
            child: FutureBuilder<List<String>>(
              future: taskNamesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = searchQuery.trim().toLowerCase();
                final taskNames = snapshot.data!.where((taskName) {
                  final enabled = isTaskEnabled(taskName);
                  if (filter == _EnableTaskFilter.enabled && !enabled) {
                    return false;
                  }
                  if (filter == _EnableTaskFilter.disabled && enabled) {
                    return false;
                  }
                  return query.isEmpty ||
                      taskName.toLowerCase().contains(query) ||
                      taskName.tr.toLowerCase().contains(query);
                }).toList();
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: const Icon(Icons.search_rounded),
                              hintText: '搜索任务'.tr,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) =>
                                setDialogState(() => searchQuery = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<_EnableTaskFilter>(
                          tooltip: _filterLabel(filter),
                          initialValue: filter,
                          onSelected: (value) =>
                              setDialogState(() => filter = value),
                          itemBuilder: (context) => _EnableTaskFilter.values
                              .map(
                                (value) => PopupMenuItem<_EnableTaskFilter>(
                                  value: value,
                                  child: Text(_filterLabel(value)),
                                ),
                              )
                              .toList(),
                          icon: Icon(
                            Icons.filter_list_rounded,
                            color: filter == _EnableTaskFilter.all
                                ? null
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '已启用任务仅供查看；可多选未启用任务进行启用。已停用任务会保留私有配置和运行记录。'.tr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: taskNames.isEmpty
                          ? Center(child: Text('没有可启用的任务'.tr))
                          : ListView.builder(
                              itemCount: taskNames.length,
                              itemBuilder: (context, index) {
                                final taskName = taskNames[index];
                                final enabled = isTaskEnabled(taskName);
                                final selected = selectedTaskNames.contains(
                                  taskName,
                                );
                                return CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                  value: enabled || selected,
                                  title: Text(
                                    taskName.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: enabled ? Text('已启用'.tr) : null,
                                  onChanged: enabled
                                      ? null
                                      : (value) => setDialogState(() {
                                          if (value == true) {
                                            selectedTaskNames.add(taskName);
                                          } else {
                                            selectedTaskNames.remove(taskName);
                                          }
                                        }),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(I18n.cancel.tr),
            ),
            FilledButton.icon(
              onPressed: selectedTaskNames.isEmpty
                  ? null
                  : () => Navigator.of(
                      dialogContext,
                    ).pop(selectedTaskNames.toList()),
              icon: const Icon(Icons.playlist_add_rounded),
              label: Text('启用（${selectedTaskNames.length}）'.tr),
            ),
          ],
        ),
      ),
    );
  } finally {
    searchController.dispose();
  }
}

String _filterLabel(_EnableTaskFilter filter) => switch (filter) {
  _EnableTaskFilter.all => '全部任务'.tr,
  _EnableTaskFilter.enabled => '已启用'.tr,
  _EnableTaskFilter.disabled => '未启用'.tr,
};
