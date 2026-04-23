import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/view/slide_page_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlidePageController', () {
    testWidgets('沒有 clients 時不會提早消費 jump callback', (tester) async {
      final pageController = PageController();
      final slideController = SlidePageController(pageController);
      var callbackCalled = false;

      slideController.jumpTo(1, onWillJump: () => callbackCalled = true);
      await tester.pump();

      expect(callbackCalled, isFalse);

      slideController.dispose();
      pageController.dispose();
    });

    testWidgets('clients attach 後會補上先前延後的 jump', (tester) async {
      final pageController = PageController();
      final slideController = SlidePageController(pageController);
      var callbackCalled = false;

      slideController.jumpTo(1, onWillJump: () => callbackCalled = true);
      await tester.pump();

      expect(callbackCalled, isFalse);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PageView(
            controller: pageController,
            children: const [SizedBox.expand(), SizedBox.expand()],
          ),
        ),
      );
      await tester.pump();

      expect(callbackCalled, isTrue);
      expect(pageController.page, 1);

      slideController.dispose();
      pageController.dispose();
    });

    testWidgets('實際 jumpToPage 前才消費 jump callback', (tester) async {
      final pageController = PageController(initialPage: 0);
      final slideController = SlidePageController(pageController);
      var callbackCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PageView(
            controller: pageController,
            children: const [SizedBox.expand(), SizedBox.expand()],
          ),
        ),
      );

      slideController.jumpTo(1, onWillJump: () => callbackCalled = true);

      expect(callbackCalled, isFalse);
      await tester.pump();

      expect(callbackCalled, isTrue);
      expect(pageController.page, 1);

      slideController.dispose();
      pageController.dispose();
    });
  });
}
