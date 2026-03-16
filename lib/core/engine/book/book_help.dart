import 'package:legado_reader/core/constant/app_pattern.dart';

/// BookHelp - 輔助書籍處理工具 (原 Android help/book/BookHelp.kt)
class BookHelp {
  BookHelp._();

  /// 格式化書名 (對標 Android BookHelp.formatBookName)
  static String formatBookName(String name) {
    return name.replaceAll(AppPattern.nameRegex, '').trim();
  }

  /// 格式化作者 (對標 Android BookHelp.formatBookAuthor)
  static String formatBookAuthor(String author) {
    return author.replaceAll(AppPattern.authorRegex, '').trim();
  }
}
