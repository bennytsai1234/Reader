import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_exit_coordinator.dart';

class _ExitFlowProbe implements ReaderExitFlowDelegate {
  _ExitFlowProbe(this.book);

  @override
  final Book book;

  bool promptAddToBookshelf = false;
  int persistCalls = 0;
  int addToBookshelfCalls = 0;
  int discardCalls = 0;
  Completer<void>? persistCompleter;

  @override
  bool shouldPromptAddToBookshelfOnExit() {
    return promptAddToBookshelf;
  }

  @override
  Future<void> persistExitProgress() async {
    persistCalls++;
    final completer = persistCompleter;
    if (completer != null) {
      await completer.future;
    }
  }

  @override
  Future<void> addCurrentBookToBookshelf() async {
    addToBookshelfCalls++;
  }

  @override
  Future<void> discardUnkeptBookStorage() async {
    discardCalls++;
  }
}

Book _makeBook() => Book(
  bookUrl: 'https://example.com/book',
  name: '示例書籍',
  author: '作者',
  origin: 'source://demo',
  originName: '測試書源',
);

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();
  return captured;
}

void main() {
  testWidgets('drawer 開啟時 exit intent 只會要求 pop，不會持久化', (tester) async {
    final provider = _ExitFlowProbe(_makeBook());
    final coordinator = ReaderPageExitCoordinator();
    final context = await _pumpContext(tester);
    var popCalls = 0;

    await coordinator.handleExitIntent(
      context: context,
      provider: provider,
      isDrawerOpen: () => true,
      popNavigator: () => popCalls++,
    );

    expect(popCalls, 1);
    expect(provider.persistCalls, 0);
    expect(provider.addToBookshelfCalls, 0);
  });

  testWidgets('不需要 prompt 時會先保存進度再 pop', (tester) async {
    final provider = _ExitFlowProbe(_makeBook());
    final coordinator = ReaderPageExitCoordinator();
    final context = await _pumpContext(tester);
    var popCalls = 0;

    await coordinator.handleExitIntent(
      context: context,
      provider: provider,
      isDrawerOpen: () => false,
      popNavigator: () => popCalls++,
    );

    expect(provider.persistCalls, 1);
    expect(provider.addToBookshelfCalls, 0);
    expect(provider.discardCalls, 1);
    expect(popCalls, 1);
  });

  testWidgets('需要 prompt 且選擇加入書架時會保存、加入並 pop', (tester) async {
    final provider = _ExitFlowProbe(_makeBook())..promptAddToBookshelf = true;
    final coordinator = ReaderPageExitCoordinator(
      promptAddToBookshelf: (_, __) async => true,
    );
    final context = await _pumpContext(tester);
    var popCalls = 0;

    await coordinator.handleExitIntent(
      context: context,
      provider: provider,
      isDrawerOpen: () => false,
      popNavigator: () => popCalls++,
    );

    expect(provider.persistCalls, 1);
    expect(provider.addToBookshelfCalls, 1);
    expect(provider.discardCalls, 0);
    expect(popCalls, 1);
  });

  testWidgets('需要 prompt 且選擇不加入時會移除未保留 storage', (tester) async {
    final provider = _ExitFlowProbe(_makeBook())..promptAddToBookshelf = true;
    final coordinator = ReaderPageExitCoordinator(
      promptAddToBookshelf: (_, __) async => false,
    );
    final context = await _pumpContext(tester);
    var popCalls = 0;

    await coordinator.handleExitIntent(
      context: context,
      provider: provider,
      isDrawerOpen: () => false,
      popNavigator: () => popCalls++,
    );

    expect(provider.persistCalls, 1);
    expect(provider.addToBookshelfCalls, 0);
    expect(provider.discardCalls, 1);
    expect(popCalls, 1);
  });

  testWidgets('exit flow 進行中會忽略重入', (tester) async {
    final provider = _ExitFlowProbe(_makeBook())
      ..persistCompleter = Completer<void>();
    final coordinator = ReaderPageExitCoordinator();
    final context = await _pumpContext(tester);
    var popCalls = 0;

    final first = coordinator.handleExitIntent(
      context: context,
      provider: provider,
      isDrawerOpen: () => false,
      popNavigator: () => popCalls++,
    );
    await tester.pump();

    await coordinator.handleExitIntent(
      context: context,
      provider: provider,
      isDrawerOpen: () => false,
      popNavigator: () => popCalls++,
    );

    expect(provider.persistCalls, 1);
    expect(popCalls, 0);

    provider.persistCompleter!.complete();
    await tester.pump();
    await first;

    expect(popCalls, 1);
  });
}
