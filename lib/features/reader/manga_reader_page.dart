import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';

import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'widgets/manga/manga_image_view.dart';
import 'widgets/manga/manga_top_bar.dart';
import 'widgets/manga/manga_bottom_controls.dart';
import 'package:legado_reader/core/di/injection.dart';

class MangaReaderPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  const MangaReaderPage({super.key, required this.book, this.chapterIndex = 0});
  @override State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  late int _currentIndex;
  List<String> _urls = [];
  bool _isLoading = true;
  List<BookChapter> _chapters = [];
  bool _showControls = true;
  double _brightness = 1.0;
  int _currentPage = 0;
  int _readingMode = 0;
  bool _isReverse = false;
  bool _isAutoScrolling = false;
  Timer? _scrollTimer;

  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();
  final TransformationController _transCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.chapterIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _init();
    _scrollCtrl.addListener(() {
      if (_readingMode != 1) {
        setState(() => _currentPage = (_scrollCtrl.offset / 600).floor().clamp(0, _urls.length - 1));
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollCtrl.dispose();
    _pageCtrl.dispose();
    _transCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _init() async {
    _chapters = await getIt<ChapterDao>().getChapters(widget.book.bookUrl);
    _loadChapter(_currentIndex);
  }

  Future<void> _loadChapter(int i) async {
    final s = await getIt<BookSourceDao>().getByUrl(widget.book.origin);
    if (s == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _currentIndex = i;
    });
    try {
      final content = await BookSourceService().getContent(s, widget.book, _chapters[i]);
      _urls = content.split(RegExp(r'[\n\r,]+')).where((e) => e.trim().isNotEmpty).toList();
    } catch (_) {} 
    finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleAutoScroll() {
    if (_readingMode == 1) {
      return;
    }
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
      _showControls = false;
    });
    if (_isAutoScrolling) {
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
        if (_scrollCtrl.hasClients) {
          if (_scrollCtrl.offset >= _scrollCtrl.position.maxScrollExtent) {
            _stopAutoScroll();
            if (_currentIndex < _chapters.length - 1) {
              _loadChapter(_currentIndex + 1);
            }
          } else {
            _scrollCtrl.jumpTo(_scrollCtrl.offset + 2.0);
          }
        }
      });
    } else {
      _scrollTimer?.cancel();
    }
  }

  void _stopAutoScroll() {
    if (_isAutoScrolling) {
      setState(() => _isAutoScrolling = false);
      _scrollTimer?.cancel();
    }
  }

  void _handleTap(TapUpDetails d, double w) {
    final x = d.globalPosition.dx;
    if (x < w / 3) {
      (_isReverse && _readingMode == 1) ? _next() : _prev();
    } else if (x > w * 2 / 3) {
      (_isReverse && _readingMode == 1) ? _prev() : _next();
    } else {
      setState(() => _showControls = !_showControls);
    }
  }

  void _next() {
    if (_readingMode == 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.linear);
    } else {
      _scrollCtrl.animateTo(_scrollCtrl.offset + 500, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    }
  }

  void _prev() {
    if (_readingMode == 1) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.linear);
    } else {
      _scrollCtrl.animateTo(_scrollCtrl.offset - 500, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (ctx, constraints) => Stack(
          children: [
            GestureDetector(
              onTapUp: (d) => _handleTap(d, constraints.maxWidth),
              onDoubleTapDown: (d) {
                if (_transCtrl.value != Matrix4.identity()) {
                  _transCtrl.value = Matrix4.identity();
                } else {
                  _transCtrl.value = Matrix4.identity()
                    ..translateByDouble(-d.localPosition.dx, -d.localPosition.dy, 0.0, 1.0)
                    ..scaleByDouble(2.0, 2.0, 1.0, 1.0);
                }
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : InteractiveViewer(
                      transformationController: _transCtrl,
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: _readingMode == 1
                          ? PageView.builder(
                              controller: _pageCtrl,
                              reverse: _isReverse,
                              itemCount: _urls.length,
                              onPageChanged: (i) => setState(() => _currentPage = i),
                              itemBuilder: (c, i) => MangaImageView(imageUrl: _urls[i], readingMode: _readingMode),
                            )
                          : ListView.builder(
                              controller: _scrollCtrl,
                              itemCount: _urls.length,
                              padding: EdgeInsets.zero,
                              itemBuilder: (c, i) => MangaImageView(imageUrl: _urls[i], readingMode: _readingMode),
                            ),
                    ),
            ),
            if (!_showControls) Positioned(bottom: 4, left: 0, right: 0, child: _buildInfoBar()),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: MangaTopBar(bookName: widget.book.name, onBack: () => Navigator.pop(context), onShowToc: _showToc),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? 0 : -150,
              left: 0,
              right: 0,
              child: MangaBottomControls(
                readingMode: _readingMode,
                isAutoScrolling: _isAutoScrolling,
                isReverseDirection: _isReverse,
                brightness: _brightness,
                hasPrev: _currentIndex > 0,
                hasNext: _currentIndex < _chapters.length - 1,
                onModeChanged: (v) => setState(() => _readingMode = v),
                onToggleAutoScroll: _toggleAutoScroll,
                onToggleDirection: () => setState(() => _isReverse = !_isReverse),
                onBrightnessChanged: (v) => setState(() => _brightness = v),
                onPrevChapter: () => _loadChapter(_currentIndex - 1),
                onNextChapter: () => _loadChapter(_currentIndex + 1),
              ),
            ),
            if (_brightness < 1.0) IgnorePointer(child: Container(color: Colors.black.withValues(alpha: 1.0 - _brightness))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        color: Colors.black.withValues(alpha: 0.4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_chapters.isNotEmpty ? _chapters[_currentIndex].title : ""} (${_currentPage + 1}/${_urls.length})', style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(DateFormat('HH:mm').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      );

  void _showToc() => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey[900],
        builder: (ctx) => ListView.builder(
          itemCount: _chapters.length,
          itemBuilder: (c, i) => ListTile(
            title: Text(_chapters[i].title, style: TextStyle(color: i == _currentIndex ? Colors.blue : Colors.white70)),
            onTap: () {
              Navigator.pop(ctx);
              _loadChapter(i);
            },
          ),
        ),
      );
}


