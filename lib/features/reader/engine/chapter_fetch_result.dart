class FetchResult {
  final String content;
  final String? displayTitle;
  final String? failureMessage;

  FetchResult({required this.content, this.displayTitle, this.failureMessage});
}

typedef ChapterFetchFn = Future<FetchResult> Function(int chapterIndex);
