/// BookProgress - 書籍進度同步模型
/// (原 Android data/entities/BookProgress.kt)
class BookProgress {
  final String name;
  final String author;
  final int chapterIndex;
  final int charOffset;
  final String durChapterTitle;
  final int durChapterTime;

  BookProgress({
    required this.name,
    required this.author,
    required this.chapterIndex,
    required this.charOffset,
    required this.durChapterTitle,
    required this.durChapterTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'author': author,
      'chapterIndex': chapterIndex,
      'charOffset': charOffset,
      'durChapterTitle': durChapterTitle,
      'durChapterTime': durChapterTime,
    };
  }

  factory BookProgress.fromJson(Map<String, dynamic> json) {
    return BookProgress(
      name: json['name'] ?? '',
      author: json['author'] ?? '',
      chapterIndex: json['chapterIndex'] ?? 0,
      charOffset: json['charOffset'] ?? 0,
      durChapterTitle: json['durChapterTitle'] ?? '',
      durChapterTime: json['durChapterTime'] ?? 0,
    );
  }
}
