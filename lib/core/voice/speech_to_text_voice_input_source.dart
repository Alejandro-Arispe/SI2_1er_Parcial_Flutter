import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:fashion_store/core/voice/voice_input_source.dart';

/// Implementación real del dictado por voz (Fase 22, sección 18 del
/// documento) usando `speech_to_text`: reconocimiento on-device provisto
/// por el sistema operativo (Android SpeechRecognizer), sin enviar audio
/// a Gemini ni a ningún otro servicio propio (la voz solo llena el campo
/// de texto del asistente; el mensaje resultante sigue el mismo camino
/// Flutter -> FastAPI -> Gemini de siempre, sección 14).
class SpeechToTextVoiceInputSource implements VoiceInputSource {
  final SpeechToText _speech = SpeechToText();
  final _transcriptController = StreamController<String>.broadcast();
  bool _isReady = false;

  @override
  bool get isListening => _speech.isListening;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Future<bool> initialize() async {
    if (_isReady) return true;
    // onError y onStatus no necesitan lógica propia: un error puntual de
    // reconocimiento simplemente deja de escuchar (isListening pasa a
    // false), que ya es lo que refleja VoiceInputController.
    _isReady = await _speech.initialize(onError: (_) {}, onStatus: (_) {});
    return _isReady;
  }

  @override
  Future<void> startListening() async {
    if (!_isReady) return;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (!_transcriptController.isClosed) {
          _transcriptController.add(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        // Todo el catálogo y la app están en español: se fuerza el
        // idioma en vez de depender del idioma del sistema del
        // dispositivo.
        localeId: 'es_ES',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Future<void> stopListening() => _speech.stop();

  @override
  Future<void> dispose() async {
    await _speech.cancel();
    await _transcriptController.close();
  }
}

final voiceInputSourceProvider = Provider.autoDispose<VoiceInputSource>((ref) {
  final source = SpeechToTextVoiceInputSource();
  // El dueño del recurso es este provider: se libera el reconocedor de
  // voz apenas deja de observarse (al salir de la pantalla del
  // asistente), igual que arCameraSourceProvider en el probador AR.
  ref.onDispose(() => source.dispose());
  return source;
});
