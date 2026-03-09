import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_cache.dart';

class AISettingsNotifier extends Notifier<String?> {
  static const _apiKeyCacheKey = 'gemini_api_key';

  @override
  String? build() {
    final cache = ref.watch(appCacheProvider);
    return cache.readString(_apiKeyCacheKey);
  }

  Future<void> setApiKey(String key) async {
    state = key;
    final cache = ref.read(appCacheProvider);
    await cache.writeString(_apiKeyCacheKey, key);
  }

  Future<void> clearApiKey() async {
    state = null;
    final cache = ref.read(appCacheProvider);
    await cache.remove(_apiKeyCacheKey);
  }
}

final aiSettingsProvider = NotifierProvider<AISettingsNotifier, String?>(() {
  return AISettingsNotifier();
});
