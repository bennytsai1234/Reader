import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'core/di/injection.dart';
import 'core/services/tts_service.dart';
import 'features/bookshelf/bookshelf_provider.dart';
import 'features/explore/explore_provider.dart';
import 'features/source_manager/source_manager_provider.dart';
import 'features/search/search_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/settings/font_provider.dart';
import 'features/dict/dict_provider.dart';
import 'features/book_detail/change_cover_provider.dart';

/// AppProviders - 集中管理全域 Provider
class AppProviders {
  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider(create: (_) => SourceManagerProvider()),
    ChangeNotifierProvider(create: (_) => SearchProvider()),
    ChangeNotifierProvider(create: (_) => BookshelfProvider()),
    ChangeNotifierProvider(create: (_) => ExploreProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => FontProvider()),
    ChangeNotifierProvider(create: (_) => ChangeCoverProvider()),
    ChangeNotifierProvider(create: (_) => DictProvider()),
    // TTSService 從 getIt 獲取單例，保持全域一致性
    ChangeNotifierProvider.value(value: getIt<TTSService>()),
  ];
}

