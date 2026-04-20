import 'package:flutter_test/flutter_test.dart';

import 'package:inkpage_reader/features/settings/other_settings_page.dart';
import 'package:inkpage_reader/features/settings/tts_settings_page.dart';

void main() {
  test('Settings pages can be constructed', () {
    expect(() => const OtherSettingsPage(), returnsNormally);
    expect(() => const TtsSettingsPage(), returnsNormally);
  });
}
