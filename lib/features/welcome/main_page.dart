import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/features/settings/settings_provider.dart';
import 'package:legado_reader/features/bookshelf/bookshelf_page.dart';
import 'package:legado_reader/features/explore/explore_page.dart';
import 'package:legado_reader/features/settings/settings_page.dart';
import 'package:legado_reader/features/bookshelf/bookshelf_provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  DateTime _lastTapTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 移除 WebDAV 初始化相關邏輯
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      final items = <Map<String, dynamic>>[
        {'icon': Icons.book_outlined, 'selectedIcon': Icons.book, 'label': '書架', 'page': const BookshelfPage()}
      ];
      
      if (settings.showDiscovery) {
        items.add({'icon': Icons.explore_outlined, 'selectedIcon': Icons.explore, 'label': '發現', 'page': const ExplorePage()});
      }
      
      items.add({'icon': Icons.person_outline, 'selectedIcon': Icons.person, 'label': '我的', 'page': const SettingsPage()});

      return Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: items.map((i) => i['page'] as Widget).toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (_currentIndex == index) {
              if (DateTime.now().difference(_lastTapTime).inMilliseconds < 300) {
                final label = items[index]['label'];
                if (label == '書架') {
                  context.read<BookshelfProvider>().loadBooks();
                }
              }
              _lastTapTime = DateTime.now();
            }
            setState(() => _currentIndex = index);
          },
          destinations: items.map((i) => NavigationDestination(
            icon: i['icon'] is Widget ? i['icon'] : Icon(i['icon'] as IconData), 
            selectedIcon: i['selectedIcon'] is Widget ? i['selectedIcon'] : Icon(i['selectedIcon'] as IconData),
            label: i['label']
          )).toList(),
        ),
      );
    });
  }
}
