import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_gesture_layer.dart';

void main() {
  testWidgets('disabling gestures keeps content subtree mounted', (
    tester,
  ) async {
    var initCount = 0;
    var disposeCount = 0;

    Widget build({required bool gesturesEnabled}) {
      return MaterialApp(
        home: ReaderV2GestureLayer(
          gesturesEnabled: gesturesEnabled,
          onTapUp: (_) {},
          child: _Probe(
            onInit: () => initCount += 1,
            onDispose: () => disposeCount += 1,
          ),
        ),
      );
    }

    await tester.pumpWidget(build(gesturesEnabled: true));
    expect(initCount, 1);
    expect(disposeCount, 0);

    await tester.pumpWidget(build(gesturesEnabled: false));
    expect(initCount, 1);
    expect(disposeCount, 0);
  });

  testWidgets('jittery tap is still reported as content tap', (tester) async {
    var tapCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: ReaderV2GestureLayer(
            onTapUp: (_) => tapCalls += 1,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(120, 180));
    await gesture.moveBy(const Offset(4, 3));
    await gesture.up();
    await tester.pump();

    expect(tapCalls, 1);
  });

  testWidgets('stationary tap is reported as content tap', (tester) async {
    var tapCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: ReaderV2GestureLayer(
            onTapUp: (_) => tapCalls += 1,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(120, 180));
    await tester.pump();

    expect(tapCalls, 1);
  });

  testWidgets('drag remains available to viewport child', (tester) async {
    var tapCalls = 0;
    var dragUpdates = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: ReaderV2GestureLayer(
            onTapUp: (_) => tapCalls += 1,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (_) => dragUpdates += 1,
              child: const ColoredBox(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(120, 180));
    await gesture.moveBy(const Offset(0, 42));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(tapCalls, 0);
    expect(dragUpdates, greaterThan(0));
  });
}

class _Probe extends StatefulWidget {
  const _Probe({required this.onInit, required this.onDispose});

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
