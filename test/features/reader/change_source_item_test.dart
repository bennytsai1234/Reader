import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/features/reader/widgets/change_source_item.dart';

SearchBook _makeSearchBook() {
  return SearchBook(
    bookUrl: 'https://example.com/book/1',
    name: '測試書',
    author: '作者甲',
    kind: '玄幻',
    wordCount: '120萬字',
    latestChapterTitle: '第 120 章',
    origin: 'source://main',
    originName: '主書源',
    respondTime: 520,
  );
}

void main() {
  testWidgets('會顯示目前來源狀態與來源資訊', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeSourceItem(
            searchBook: _makeSearchBook(),
            isCurrent: true,
          ),
        ),
      ),
    );

    expect(find.text('主書源'), findsOneWidget);
    expect(find.text('作者: 作者甲'), findsOneWidget);
    expect(find.text('最新: 第 120 章'), findsOneWidget);
    expect(find.text('120萬字'), findsOneWidget);
    expect(find.text('玄幻'), findsOneWidget);
    expect(find.text('520ms'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
