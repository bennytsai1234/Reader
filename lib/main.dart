import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'core/di/injection.dart';
import 'core/database/dao/book_dao.dart';
import 'core/services/tts_service.dart';
import 'app_providers.dart';
import 'shared/theme/app_theme.dart';
import 'features/settings/settings_provider.dart';
import 'features/welcome/splash_page.dart';
import 'core/services/app_log_service.dart';

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
const String kAppDisplayName = '保安專用閱讀器';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppLog.i('WidgetsFlutterBinding Initialized');

    // 自定義錯誤畫面，避免黑屏
    ErrorWidget.builder = (FlutterErrorDetails details) {
      AppLog.e('Rendering Error: ${details.exception}', error: details.exception, stackTrace: details.stack);
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Detected an Error:', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(details.exceptionAsString(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 10),
                Text(details.stack.toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ),
      );
    };

    try {
      AppLog.i('Configuring Dependencies...');
      await configureDependencies();
      AppLog.i('Dependencies Configured Successfully');

      if (kDebugMode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('recordLog', true);
        AppLog.i('Debug Mode: recordLog forced to TRUE');
      }
      
      AppLog.i('Initializing TTSService...');
      await TTSService().init();

      AppLog.i('Initializing Workmanager...');
      Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLog.e('Flutter Error: ${details.exception}', error: details.exception, stackTrace: details.stack);
      };

      AppLog.i('$kAppDisplayName Ready to Run');

      runApp(
        MultiProvider(
          providers: AppProviders.providers,
          child: const LegadoReaderApp(),
        ),
      );
    } catch (e, stack) {
      AppLog.e('Startup Critical Error: $e', error: e, stackTrace: stack);
      runApp(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SelectableText('Startup Failed:\n$e\n\n$stack', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ));
    }
  }, (error, stack) {
    AppLog.e('Uncaught Error: $error', error: error, stackTrace: stack);
  });
}

class LegadoReaderApp extends StatefulWidget {
  const LegadoReaderApp({super.key});

  @override
  State<LegadoReaderApp> createState() => _LegadoReaderAppState();
}

class _LegadoReaderAppState extends State<LegadoReaderApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: kAppDisplayName,
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

