import 'book_source_base.dart';
import 'book_source_rules.dart';
import '../../constant/source_type.dart';

const String nonNovelSourceGroupTag = '非小說源';

const List<String> _nonNovelSourceMarkers = <String>[
  '有声',
  '有聲',
  '听书',
  '聽書',
  '音频',
  '音頻',
  '广播剧',
  '廣播劇',
  'podcast',
  'radio',
  '漫画',
  '漫畫',
  'manga',
  'manhwa',
  'comic',
  '動漫',
  '动漫',
  '番劇',
  '番剧',
  '视频',
  '視頻',
  '影片',
  '影视',
  '影視',
  '电影',
  '電影',
  'm3u8',
];

/// BookSource 的業務邏輯擴展
extension BookSourceLogic on BookSourceBase {
  // --- 安全規則獲取 (延遲加載) ---
  SearchRule getSearchRule() => ruleSearch ??= SearchRule();
  ExploreRule getExploreRule() => ruleExplore ??= ExploreRule();
  BookInfoRule getBookInfoRule() => ruleBookInfo ??= BookInfoRule();
  TocRule getTocRule() => ruleToc ??= TocRule();
  ContentRule getContentRule() => ruleContent ??= ContentRule();
  ReviewRule getReviewRule() => ruleReview ??= ReviewRule();

  // 分組操作
  void addGroup(String groups) {
    final currentGroups =
        bookSourceGroup
            ?.split(RegExp(r'[,，\s]+'))
            .where((s) => s.trim().isNotEmpty)
            .toSet() ??
        {};
    currentGroups.addAll(
      groups.split(RegExp(r'[,，\s]+')).where((s) => s.trim().isNotEmpty),
    );
    bookSourceGroup = currentGroups.isEmpty ? null : currentGroups.join(',');
  }

  void removeGroup(String groups) {
    final currentGroups =
        bookSourceGroup
            ?.split(RegExp(r'[,，\s]+'))
            .where((s) => s.trim().isNotEmpty)
            .toSet() ??
        {};
    currentGroups.removeAll(
      groups.split(RegExp(r'[,，\s]+')).where((s) => s.trim().isNotEmpty),
    );
    bookSourceGroup = currentGroups.isEmpty ? null : currentGroups.join(',');
  }

  void removeInvalidGroups() {
    if (bookSourceGroup == null) return;
    final invalidPattern = RegExp(r'失效|校驗超時');
    final currentGroups =
        bookSourceGroup!
            .split(RegExp(r'[,，\s]+'))
            .where((s) => s.isNotEmpty)
            .toList();
    currentGroups.removeWhere((g) => invalidPattern.hasMatch(g));
    bookSourceGroup = currentGroups.isEmpty ? null : currentGroups.join(',');
  }

  // 註釋與錯誤訊息
  void removeErrorComment() {
    if (bookSourceComment == null) return;
    bookSourceComment = bookSourceComment!
        .split('\n\n')
        .where((line) => !line.trim().startsWith('// Error:'))
        .join('\n\n');
  }

  void addErrorComment(String error) {
    removeErrorComment();
    final newErrorLine = '// Error: $error';
    bookSourceComment =
        (bookSourceComment == null || bookSourceComment!.isEmpty)
            ? newErrorLine
            : '$newErrorLine\n\n$bookSourceComment';
  }

  bool get isNovelTextSource => nonNovelExclusionReason == null;

  String? get nonNovelExclusionReason {
    if (bookSourceType != SourceType.book) {
      return 'sourceType:$bookSourceType';
    }
    final marker = detectedNonNovelMarker;
    if (marker != null) {
      return 'marker:$marker';
    }
    return null;
  }

  String? get detectedNonNovelMarker {
    final haystack =
        <String>[
          bookSourceName,
          bookSourceGroup ?? '',
          bookSourceComment ?? '',
          bookSourceUrl,
          exploreUrl ?? '',
          searchUrl ?? '',
        ].join('\n').toLowerCase();

    for (final marker in _nonNovelSourceMarkers) {
      if (haystack.contains(marker.toLowerCase())) {
        return marker;
      }
    }
    return null;
  }
}
