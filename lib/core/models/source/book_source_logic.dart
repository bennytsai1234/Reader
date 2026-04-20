import 'book_source_base.dart';
import 'book_source_rules.dart';
import '../../constant/source_type.dart';

const String searchBrokenSourceGroupTag = '搜尋失效';
const String detailBrokenSourceGroupTag = '詳情失效';
const String tocBrokenSourceGroupTag = '目錄失效';
const String contentBrokenSourceGroupTag = '正文失效';
const String timeoutSourceGroupTag = '校驗超時';
const String siteBrokenSourceGroupTag = '網站失效';
const String upstreamBlockedSourceGroupTag = '上游異常';
const String downloadOnlySourceGroupTag = '下載站';
const String quarantineSourceGroupTag = '已隔離';
const String nonNovelSourceGroupTag = '非小說源';
const String loginRequiredSourceGroupTag = '需要登入';

const List<String> sourceRuntimeStatusTags = <String>[
  searchBrokenSourceGroupTag,
  detailBrokenSourceGroupTag,
  tocBrokenSourceGroupTag,
  contentBrokenSourceGroupTag,
  timeoutSourceGroupTag,
  siteBrokenSourceGroupTag,
  upstreamBlockedSourceGroupTag,
  downloadOnlySourceGroupTag,
  quarantineSourceGroupTag,
  nonNovelSourceGroupTag,
  loginRequiredSourceGroupTag,
];

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

enum SourceHealthCategory {
  healthy,
  nonNovel,
  loginRequired,
  downloadOnly,
  searchBroken,
  detailBroken,
  tocBroken,
  contentBroken,
  upstreamUnstable,
}

class SourceRuntimeHealth {
  final SourceHealthCategory category;
  final String label;
  final String description;
  final bool allowsSearch;
  final bool allowsReading;
  final bool cleanupCandidate;
  final bool quarantined;

  const SourceRuntimeHealth({
    required this.category,
    required this.label,
    required this.description,
    required this.allowsSearch,
    required this.allowsReading,
    required this.cleanupCandidate,
    required this.quarantined,
  });

  static const SourceRuntimeHealth healthy = SourceRuntimeHealth(
    category: SourceHealthCategory.healthy,
    label: '可用',
    description: '目前未發現會阻塞搜尋或閱讀的問題',
    allowsSearch: true,
    allowsReading: true,
    cleanupCandidate: false,
    quarantined: false,
  );
}

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
    removeGroup(sourceRuntimeStatusTags.join(','));
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

  Set<String> get groupTags =>
      (bookSourceGroup ?? '')
          .split(RegExp(r'[,，\s]+'))
          .map((group) => group.trim())
          .where((group) => group.isNotEmpty)
          .toSet();

  bool hasGroupTag(String tag) => groupTags.contains(tag);

  SourceRuntimeHealth get runtimeHealth {
    if (!isNovelTextSource || hasGroupTag(nonNovelSourceGroupTag)) {
      return const SourceRuntimeHealth(
        category: SourceHealthCategory.nonNovel,
        label: nonNovelSourceGroupTag,
        description: '來源不是純文字小說書源',
        allowsSearch: false,
        allowsReading: false,
        cleanupCandidate: true,
        quarantined: false,
      );
    }

    if (hasGroupTag(downloadOnlySourceGroupTag)) {
      return const SourceRuntimeHealth(
        category: SourceHealthCategory.downloadOnly,
        label: downloadOnlySourceGroupTag,
        description: '來源只提供下載，不提供線上正文閱讀',
        allowsSearch: false,
        allowsReading: false,
        cleanupCandidate: true,
        quarantined: false,
      );
    }

    if (hasGroupTag(loginRequiredSourceGroupTag)) {
      return const SourceRuntimeHealth(
        category: SourceHealthCategory.loginRequired,
        label: loginRequiredSourceGroupTag,
        description: '來源需要登入後才能使用',
        allowsSearch: false,
        allowsReading: false,
        cleanupCandidate: true,
        quarantined: false,
      );
    }

    if (hasGroupTag(searchBrokenSourceGroupTag)) {
      return const SourceRuntimeHealth(
        category: SourceHealthCategory.searchBroken,
        label: searchBrokenSourceGroupTag,
        description: '搜尋已失效，會自動從預設搜尋池排除',
        allowsSearch: false,
        allowsReading: true,
        cleanupCandidate: false,
        quarantined: false,
      );
    }

    if (hasGroupTag(detailBrokenSourceGroupTag)) {
      return const SourceRuntimeHealth(
        category: SourceHealthCategory.detailBroken,
        label: detailBrokenSourceGroupTag,
        description: '詳情頁失效，來源已隔離',
        allowsSearch: false,
        allowsReading: false,
        cleanupCandidate: false,
        quarantined: true,
      );
    }

    if (hasGroupTag(tocBrokenSourceGroupTag)) {
      return const SourceRuntimeHealth(
        category: SourceHealthCategory.tocBroken,
        label: tocBrokenSourceGroupTag,
        description: '目錄失效，來源已隔離',
        allowsSearch: false,
        allowsReading: false,
        cleanupCandidate: false,
        quarantined: true,
      );
    }

    if (hasGroupTag(contentBrokenSourceGroupTag)) {
      return const SourceRuntimeHealth(
        category: SourceHealthCategory.contentBroken,
        label: contentBrokenSourceGroupTag,
        description: '正文失效，來源已隔離',
        allowsSearch: false,
        allowsReading: false,
        cleanupCandidate: false,
        quarantined: true,
      );
    }

    if (hasGroupTag(timeoutSourceGroupTag) ||
        hasGroupTag(siteBrokenSourceGroupTag) ||
        hasGroupTag(upstreamBlockedSourceGroupTag) ||
        hasGroupTag(quarantineSourceGroupTag)) {
      return const SourceRuntimeHealth(
        category: SourceHealthCategory.upstreamUnstable,
        label: quarantineSourceGroupTag,
        description: '上游暫時不可用，來源先隔離但不視為永久失效',
        allowsSearch: false,
        allowsReading: false,
        cleanupCandidate: false,
        quarantined: true,
      );
    }

    return SourceRuntimeHealth.healthy;
  }

  bool get isSearchEnabledByRuntime => enabled && runtimeHealth.allowsSearch;

  bool get isReadingEnabledByRuntime => enabled && runtimeHealth.allowsReading;

  bool get isCleanupCandidate => runtimeHealth.cleanupCandidate;

  bool get isQuarantined => runtimeHealth.quarantined;
}
