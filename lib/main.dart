import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'core/di/injection.dart';
import 'core/database/dao/book_dao.dart';
import 'app_providers.dart';
import 'shared/theme/app_theme.dart';
import 'features/settings/settings_provider.dart';
import 'features/welcome/splash_page.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 這裡需要重新初始化必要的 DI 服務 (因為後台 Isolate 不共享主執行緒狀態)
      await configureDependencies();
      
      final bookDao = getIt<BookDao>();
      final books = await bookDao.getAllInBookshelf();
      
      getIt<Logger>().i('Background Task: Checking updates for ${books.length} books');
      // 這裡可以進一步調用 CheckSourceService 執行真實更新
      
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化依賴注入與全域服務 (包含 CrashHandler, Network, TTS)
  await configureDependencies();
  
  // 2. 初始化背景任務
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  // 3. 全域錯誤捕獲 (除了 CrashHandler 內部的捕獲，這裡補足一些邊際情況)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('app_crash', true));
  };

  getIt<Logger>().i('Legado Reader Started Successfully');

  runApp(
    MultiProvider(
      providers: AppProviders.providers,
      child: const LegadoReaderApp(),
    ),
  );
}

class LegadoReaderApp extends StatelessWidget {
  const LegadoReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Legado Reader',
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          locale: settings.locale,
          home: const SplashPage(),
        );
      },
    );
  }
}

