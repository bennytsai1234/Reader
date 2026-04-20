import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/source/explore_kind.dart';
import 'package:inkpage_reader/features/search/search_page.dart';
import 'package:inkpage_reader/features/source_manager/source_editor_page.dart';

import 'explore_provider.dart';
import 'explore_show_page.dart';

/// ExplorePage - 發現主頁面
/// (對標 Android ExploreFragment + ExploreAdapter)
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreProvider(),
      child: const _ExplorePageContent(),
    );
  }
}

class _ExplorePageContent extends StatefulWidget {
  const _ExplorePageContent();

  @override
  State<_ExplorePageContent> createState() => _ExplorePageContentState();
}

class _ExplorePageContentState extends State<_ExplorePageContent> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('發現'),
        actions: [
          if (provider.groups.isNotEmpty)
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              tooltip: '按分組篩選',
              onSelected: (group) {
                _searchController.clear();
                provider.setGroupFilter(group);
              },
              itemBuilder: (ctx) {
                final items = <PopupMenuEntry<String?>>[
                  PopupMenuItem<String?>(
                    value: null,
                    child: _buildCheckedMenuRow(
                      theme,
                      checked: provider.selectedGroup == null,
                      text: '全部',
                    ),
                  ),
                ];
                items.addAll(
                  provider.groups.map((group) {
                    return PopupMenuItem<String?>(
                      value: group,
                      child: _buildCheckedMenuRow(
                        theme,
                        checked: provider.selectedGroup == group,
                        text: group,
                      ),
                    );
                  }),
                );
                return items;
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _buildSearchBar(provider, theme),
          ),
        ),
      ),
      body: _buildSourceList(provider, theme),
    );
  }

  Widget _buildCheckedMenuRow(
    ThemeData theme, {
    required bool checked,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check : Icons.circle_outlined,
          size: 18,
          color: checked ? theme.colorScheme.primary : null,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: checked ? theme.colorScheme.primary : null),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ExploreProvider provider, ThemeData theme) {
    return TextField(
      controller: _searchController,
      onChanged: provider.setSearchQuery,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText:
            provider.selectedGroup == null
                ? '搜索發現書源'
                : '分組: ${provider.selectedGroup}',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon:
            _searchController.text.isEmpty && provider.selectedGroup == null
                ? null
                : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    if (provider.selectedGroup != null) {
                      provider.setGroupFilter(null);
                    } else {
                      provider.setSearchQuery('');
                    }
                  },
                ),
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.7,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildSourceList(ExploreProvider provider, ThemeData theme) {
    if (provider.isEmpty &&
        provider.searchQuery.isEmpty &&
        provider.selectedGroup == null) {
      return const Center(
        child: Text('目前無可用發現規則的書源', style: TextStyle(color: Colors.grey)),
      );
    }

    if (provider.isEmpty) {
      return Center(
        child: Text('找不到符合條件的書源', style: TextStyle(color: Colors.grey[600])),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      itemCount: provider.sources.length,
      itemBuilder: (context, index) {
        final source = provider.sources[index];
        final isExpanded = provider.expandedIndex == index;
        return _buildSourceItem(provider, source, index, isExpanded, theme);
      },
    );
  }

  Widget _buildSourceItem(
    ExploreProvider provider,
    BookSource source,
    int index,
    bool isExpanded,
    ThemeData theme,
  ) {
    final titleBackground = theme.colorScheme.primaryContainer.withValues(
      alpha: 0.55,
    );
    final titleForeground = theme.colorScheme.onPrimaryContainer;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        index == provider.sources.length - 1 ? 12 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPressStart:
                (details) => _showSourceMenu(
                  context,
                  provider,
                  source,
                  details.globalPosition,
                ),
            child: Material(
              color: titleBackground,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: _itemKeys.putIfAbsent(source.bookSourceUrl, GlobalKey.new),
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  provider.toggleExpand(index);
                  if (!isExpanded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _ensureSourceVisible(source.bookSourceUrl);
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          source.bookSourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: titleForeground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isExpanded && provider.isLoadingKinds)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      if (isExpanded && provider.isLoadingKinds)
                        const SizedBox(width: 6),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isExpanded && !provider.isLoadingKinds)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                child:
                    provider.expandedKinds.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            '暫無分類',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                        : _buildKindTags(provider, source, theme),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKindTags(
    ExploreProvider provider,
    BookSource source,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            provider.expandedKinds.map((kind) {
              final isError = kind.title.startsWith('ERROR:');
              final background =
                  isError
                      ? Colors.red.withValues(alpha: 0.08)
                      : theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.42,
                      );
              final borderColor =
                  isError
                      ? Colors.red.withValues(alpha: 0.2)
                      : theme.colorScheme.outlineVariant;
              final textColor =
                  isError ? Colors.red.shade700 : theme.colorScheme.onSurface;

              return Material(
                color: background,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (isError) {
                      _showKindError(context, kind);
                      return;
                    }
                    if (kind.url == null || kind.url!.isEmpty) return;
                    _navigateToExploreShow(source, kind);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      kind.title,
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  void _showKindError(BuildContext context, ExploreKind kind) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('ERROR'),
            content: SelectableText(kind.url ?? kind.title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('關閉'),
              ),
            ],
          ),
    );
  }

  void _navigateToExploreShow(BookSource source, ExploreKind kind) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ExploreShowPage(
              sourceUrl: source.bookSourceUrl,
              exploreUrl: kind.url!,
              exploreName: kind.title,
            ),
      ),
    );
  }

  Future<void> _showSourceMenu(
    BuildContext context,
    ExploreProvider provider,
    BookSource source,
    Offset globalPosition,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final menuPosition = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
      Offset.zero & overlay.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: menuPosition,
      items: [
        const PopupMenuItem<String>(value: 'edit', child: Text('編輯')),
        const PopupMenuItem<String>(value: 'top', child: Text('置頂')),
        if (source.hasLoginUrl)
          const PopupMenuItem<String>(value: 'login', child: Text('登入書源')),
        const PopupMenuItem<String>(value: 'search', child: Text('搜索')),
        const PopupMenuItem<String>(value: 'refresh', child: Text('刷新分類')),
        const PopupMenuItem<String>(value: 'delete', child: Text('刪除')),
      ],
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SourceEditorPage(source: source)),
        );
        return;
      case 'top':
        await provider.topSource(source);
        return;
      case 'login':
        await _openLoginUrl(source);
        return;
      case 'search':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SearchPage(initialSource: source)),
        );
        return;
      case 'refresh':
        await provider.refreshKindsCache(source);
        return;
      case 'delete':
        _confirmDelete(context, provider, source);
        return;
    }
  }

  Future<void> _openLoginUrl(BookSource source) async {
    final loginUrl = source.loginUrl?.trim();
    if (loginUrl == null || loginUrl.isEmpty) return;
    final uri = Uri.tryParse(loginUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _confirmDelete(
    BuildContext context,
    ExploreProvider provider,
    BookSource source,
  ) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('確認'),
            content: Text('確定刪除「${source.bookSourceName}」嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  provider.deleteSource(source);
                },
                child: const Text('刪除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _ensureSourceVisible(String sourceUrl) async {
    final itemContext = _itemKeys[sourceUrl]?.currentContext;
    if (itemContext == null || !_scrollController.hasClients) return;
    await Scrollable.ensureVisible(
      itemContext,
      duration: const Duration(milliseconds: 220),
      alignment: 0.0,
      curve: Curves.easeOutCubic,
    );
  }
}
