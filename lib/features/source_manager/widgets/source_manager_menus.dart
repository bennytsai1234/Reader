import 'package:flutter/material.dart';
import '../source_manager_provider.dart';
import '../source_subscription_page.dart';

class SourceManagerMenus {
  /// 匯入與新增選單 (對標 Android menu_add_book_source 及其子項)
  static Widget buildAddMenu(
    BuildContext context,
    SourceManagerProvider provider, {
    required Function() onImportUrl,
    required Function() onImportFile,
    required Function() onImportClipboard,
    required Function() onScanQr,
    required Function() onExplore,
    required Function() onManageGroups,
    required Function() onNewSource,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add),
      tooltip: '匯入或新增',
      onSelected: (value) {
        switch (value) {
          case 'url':
            onImportUrl();
            break;
          case 'file':
            onImportFile();
            break;
          case 'clipboard':
            onImportClipboard();
            break;
          case 'qr':
            onScanQr();
            break;
          case 'explore':
            onExplore();
            break;
          case 'manage_groups':
            onManageGroups();
            break;
          case 'new':
            onNewSource();
            break;
        }
      },
      itemBuilder:
          (context) => [
            _buildItem('url', Icons.language, '網路匯入'),
            _buildItem('file', Icons.file_open_outlined, '本地匯入'),
            _buildItem('clipboard', Icons.content_paste, '剪貼簿匯入'),
            _buildItem('qr', Icons.qr_code_scanner, '掃碼匯入'),
            const PopupMenuDivider(),
            _buildItem('explore', Icons.explore_outlined, '網路書源庫'),
            _buildItem('manage_groups', Icons.groups_outlined, '管理分組'),
            _buildItem('new', Icons.add_circle_outline, '新建書源'),
          ],
    );
  }

  /// 分組與篩選選單 (對標 Android menu_group)
  static Widget buildGroupMenu(
    BuildContext context,
    SourceManagerProvider provider,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      tooltip: '篩選分組',
      onSelected: (value) {
        if (value == 'manage') {
          // 跳轉管理分組
        } else {
          provider.setFilterGroup(value);
        }
      },
      itemBuilder:
          (context) => [
            _buildCheckedItem('全部', provider.filterGroup == '全部', '全部'),
            _buildCheckedItem('已啟用', provider.filterGroup == '已啟用', '已啟用'),
            _buildCheckedItem('已禁用', provider.filterGroup == '已禁用', '已禁用'),
            _buildCheckedItem('需登錄', provider.filterGroup == '需登錄', '需登錄'),
            _buildCheckedItem('無分組', provider.filterGroup == '無分組', '無分組'),
            const PopupMenuDivider(),
            ...provider.allGroups.map(
              (g) => _buildCheckedItem(g, provider.filterGroup == g, g),
            ),
          ],
    );
  }

  /// 排序選單 (對標 Android action_sort)
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
            _buildRadioItem('3', provider.sortMode == 3, '按地址'),
            _buildRadioItem('4', provider.sortMode == 4, '按更新時間'),
            _buildRadioItem('5', provider.sortMode == 5, '按響應時間'),
          ],
    );
  }

  /// 更多操作選單 (對標 Android 溢出選單項目)
  static Widget buildMoreMenu(
    BuildContext context,
    SourceManagerProvider provider, {
    required Function(SourceManagerProvider) onClearInvalid,
    required Function(SourceManagerProvider) onDeleteNonNovel,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'check_all':
            provider.checkAllSources();
            break;
          case 'group_domain':
            provider.toggleGroupByDomain();
            break;
          case 'subscriptions':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SourceSubscriptionPage()),
            );
            break;
          case 'clear_invalid':
            onClearInvalid(provider);
            break;
          case 'clean_non_novel':
            onDeleteNonNovel(provider);
            break;
          case 'help': /* 跳轉幫助 */
            break;
        }
      },
      itemBuilder:
          (context) => [
            _buildItem('check_all', Icons.playlist_add_check, '校驗所有書源'),
            _buildCheckedItem('group_domain', provider.groupByDomain, '按域名分組'),
            _buildItem('subscriptions', Icons.rss_feed, '書源訂閱'),
            const PopupMenuDivider(),
            _buildItem('clear_invalid', Icons.delete_sweep_outlined, '清理無效書源'),
            _buildItem(
              'clean_non_novel',
              Icons.delete_forever_outlined,
              '刪除非小說源',
            ),
            _buildItem('help', Icons.help_outline, '幫助說明'),
          ],
    );
  }

  static PopupMenuItem<String> _buildItem(
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem(
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
    return PopupMenuItem(
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
    return PopupMenuItem(
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
