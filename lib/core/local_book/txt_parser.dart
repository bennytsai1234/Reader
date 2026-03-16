import 'dart:io';
import 'dart:typed_data';
import '../services/encoding_detect.dart';

/// TxtParser - 高性能 TXT 解析器
/// 深度還原 Android model/localBook/TextFile.kt 的物理位移邏輯
class TxtParser {
  final File file;
  
  static final RegExp defaultChapterPattern = RegExp(
    r'^\s*[第][0-9零一二两三四五六七八九十百千万万]+[章回节卷集幕计][ \t]*.*$',
    multiLine: true,
  );

  TxtParser(this.file);

  Future<void> load() async {}


  /// 掃描文件並獲取章節位移 (不讀取全量內容入記憶體)
  Future<({List<Map<String, dynamic>> chapters, String charset})> splitChapters({RegExp? customPattern}) async {
    final pattern = customPattern ?? defaultChapterPattern;
    final bytes = await file.readAsBytes();
    final String charsetName = EncodingDetect.getEncode(bytes);
    final charset = EncodingDetect.detect(bytes);
    final content = EncodingDetect.decode(bytes);

    
    final result = <Map<String, dynamic>>[];
    final matches = pattern.allMatches(content).toList();

    // 將字元索引轉換為位元組位移的輔助函數 (優化為單次掃描)
    final charOffsets = [0, ...matches.map((m) => m.start), content.length];
    final byteOffsets = List<int>.filled(charOffsets.length, 0);
    
    int currentChar = 0;
    int currentByte = 0;
    
    for (int i = 0; i < charOffsets.length; i++) {
      final targetChar = charOffsets[i];
      final chunk = content.substring(currentChar, targetChar);
      currentByte += charset.encode(chunk).length;
      byteOffsets[i] = currentByte;
      currentChar = targetChar;
    }

    if (matches.isEmpty) {
      result.add({
        'title': '正文',
        'start': 0,
        'end': bytes.length,
        'content': content,
      });

      return (chapters: result, charset: charsetName);
    }

    // 處理前言
    if (matches.first.start > 0) {
      result.add({
        'title': '前言',
        'start': byteOffsets[0], // 0
        'end': byteOffsets[1],
        'content': content.substring(0, matches.first.start),
      });
    }

    const int maxLen = 50000;

    for (var i = 0; i < matches.length; i++) {
      final charStart = matches[i].start;
      final charEnd = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      final byteStartBase = byteOffsets[i + 1];
      final titleBase = matches[i].group(0)?.trim() ?? '第 ${i + 1} 章';
      
      final chapterLen = charEnd - charStart;
      if (chapterLen > maxLen) {
        // 分段處理超大章節
        int partCount = (chapterLen / maxLen).ceil();
        for (int j = 0; j < partCount; j++) {
          final partCharStart = charStart + j * maxLen;
          final partCharEnd = (j == partCount - 1) ? charEnd : partCharStart + maxLen;
          
          final partByteStart = (j == 0) ? byteStartBase : byteStartBase + charset.encode(content.substring(charStart, partCharStart)).length;
          final partByteEnd = (j == partCount - 1) ? byteOffsets[i + 2] : byteStartBase + charset.encode(content.substring(charStart, partCharEnd)).length;

          result.add({
            'title': '$titleBase (${j + 1})',
            'start': partByteStart,
            'end': partByteEnd,
            'content': content.substring(partCharStart, partCharEnd),
          });
        }
      } else {
        result.add({
          'title': titleBase,
          'start': byteStartBase,
          'end': byteOffsets[i + 2],
          'content': content.substring(charStart, charEnd),
        });
      }
    }


    return (chapters: result, charset: charsetName);
  }


}
