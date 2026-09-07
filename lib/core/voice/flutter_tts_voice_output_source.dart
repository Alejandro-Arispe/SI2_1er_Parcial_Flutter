import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fashion_store/core/voice/voice_output_source.dart';

/// Implementación real de lectura en voz alta (Fase 22) usando el motor
/// de texto a voz del sistema operativo, sin ningún servicio externo de
/// por medio.
class FlutterTtsVoiceOutputSource implements VoiceOutputSource {
  final FlutterTts _tts = FlutterTts();
  bool _languageConfigured = false;

  Future<void> _ensureLanguage() async {
    if (_languageConfigured) return;
    // Todo el catálogo y la app están en español.
    await _tts.setLanguage('es-ES');
    _languageConfigured = true;
  }

  @override
  Future<void> speak(String text) async {
    await _ensureLanguage();
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}

final voiceOutputSourceProvider = Provider.autoDispose<VoiceOutputSource>((ref) {
  final source = FlutterTtsVoiceOutputSource();
  ref.onDispose(() => source.stop());
  return source;
});
