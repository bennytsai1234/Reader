import 'package:flutter/material.dart';

import '../source_manager_provider.dart';

class SourceManagerMenus {
  static Widget buildGroupMenu(
    BuildContext context,
    SourceManagerProvider provider, {
    required VoidCallback onManageGroups,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.folder_outlined),
      tooltip: '分組與篩選',
      onSelected: (value) {
        if (value == 'manage_groups') {
          onManageGroups();
          return;
        }
        provider.setFilterGroup(value);
      },
      itemBuilder:
          (context) => [
            _buildCheckedItem('全部', provider.filterGroup == '全部', '全部'),
            _buildCheckedItem('已啟用', provider.filterGroup == '已啟用', '已啟用'),
            _buildCheckedItem('已禁用', provider.filterGroup == '已禁用', '已禁用'),
            _buildCheckedItem(
              '已啟用發現',
              provider.filterGroup == '已啟用發現',
              '已啟用發現',
            ),
            _buildCheckedItem(
              '已禁用發現',
              provider.filterGroup == '已禁用發現',
              '已禁用發現',
            ),
            _buildCheckedItem('無分組', provider.filterGroup == '無分組', '無分組'),
            const PopupMenuDivider(),
            ...provider.allGroups.map(
              (group) => _buildCheckedItem(
                group,
                provider.filterGroup == group,
                group,
              ),
            ),
            const PopupMenuDivider(),
            _buildItem('manage_groups', Icons.edit_note_outlined, '管理分組'),
          ],
    );
  }

  static Widget buildSortMenu(
    BuildContext context,
    SourceManagerProvider provider,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: '排序方式',
      onSelected: (value) {
        if (value == 'desc') {
          provider.toggleSortDesc();
        } else {
          provider.setSortMode(int.parse(value));
        }
      },
      itemBuilder:
          (context) => [
            _buildCheckedItem('desc', provider.sortDesc, '倒序排列'),
            const PopupMenuDivider(),
            _buildRadioItem('0', provider.sortMode == 0, '手動排序'),
            _buildRadioItem('1', provider.sortMode == 1, '自動排序'),
            _buildRadioItem('2', provider.sortMode == 2, '按名稱'),
            _buildRadioItem('3', provider.sortMode == 3, '按網址'),
            _buildRadioItem('4', provider.sortMode == 4, '按更新時間'),
          ],
    );
  }

  static Widget buildMoreMenu(
    BuildContext context,
    SourceManagerProvider provider, {
    required VoidCallback onImportUrl,
    required VoidCallback onImportFile,
    required VoidCallback onImportClipboard,
    required VoidCallback onManageGroups,
    required VoidCallback onNewSource,
    required VoidCallback onCheckAllSources,
    required Function(SourceManagerProvider) onClearInvalid,
    required Function(SourceManagerProvider) onDeleteNonNovel,
    required Function(SourceManagerProvider) onShowLastCheckResults,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: '更多操作',
      onSelected: (value) {
        switch (value) {
          case 'import_url':
            onImportUrl();
            break;
          case 'import_file':
            onImportFile();
            break;
          case 'import_clipboard':
            onImportClipboard();
            break;
          case 'new_source':
            onNewSource();
            break;
          case 'manage_groups':
            onManageGroups();
            break;
          case 'check_all':
            onCheckAllSources();
            break;
          case 'group_domain':
            provider.toggleGroupByDomain();
            break;
          case 'check_results':
            onShowLastCheckResults(provider);
            break;
          case 'clear_invalid':
            onClearInvalid(provider);
            break;
          case 'clean_non_novel':
            onDeleteNonNovel(provider);
            break;
        }
      },
      itemBuilder:
          (context) => [
            _buildItem('import_url', Icons.language, '網路匯入'),
            _buildItem('import_file', Icons.file_open_outlined, '本地匯入'),
            _buildItem('import_clipboard', Icons.content_paste, '剪貼簿匯入'),
            _buildItem('new_source', Icons.add_circle_outline, '新建書源'),
            _buildItem('manage_groups', Icons.edit_note_outlined, '管理分組'),
            const PopupMenuDivider(),
            _buildItem('check_all', Icons.playlist_add_check, '校驗所有書源'),
            _buildCheckedItem('group_domain', provider.groupByDomain, '按域名分組'),
            if (provider.hasLastCheckReport)
              _buildItem('check_results', Icons.rule_folder_outlined, '查看校驗結果'),
            const PopupMenuDivider(),
            _buildItem(
              'clear_invalid',
              Icons.delete_sweep_outlined,
              '清理建議刪除來源',
            ),
            _buildItem(
              'clean_non_novel',
              Icons.delete_forever_outlined,
              '刪除非小說源',
            ),
          ],
    );
  }

  static PopupMenuItem<String> _buildItem(
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(text)],
      ),
    );
  }

  static PopupMenuItem<String> _buildCheckedItem(
    String value,
    bool checked,
    String text,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: checked ? Colors.blue : null,
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: checked ? Colors.blue : null)),
        ],
      ),
    );
  }

  static PopupMenuItem<String> _buildRadioItem(
    String value,
    bool checked,
    String text,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            checked ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: checked ? Colors.blue : null,
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: checked ? Colors.blue : null)),
        ],
      ),
    );
  }
}
