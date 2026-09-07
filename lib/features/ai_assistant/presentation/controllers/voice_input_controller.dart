import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/voice/speech_to_text_voice_input_source.dart';

/// Estados del dictado por voz en el composer del asistente (Fase 22,
/// sección 18 del documento). No hay un estado de "permiso rechazado"
/// separado porque speech_to_text no distingue esa causa de otras
/// fallas de inicialización (sin micrófono, sin reconocimiento de voz
/// instalado, etc.): todas se reducen a "no disponible" (sección 33:
/// el error mostrado debe ser comprensible, no necesita ser exhaustivo).
enum VoiceInputStatus { idle, unavailable, listening }

class VoiceInputState {
  final VoiceInputStatus status;
  final String transcript;

  const VoiceInputState({this.status = VoiceInputStatus.idle, this.transcript = ''});

  VoiceInputState copyWith({VoiceInputStatus? status, String? transcript}) {
    return VoiceInputState(status: status ?? this.status, transcript: transcript ?? this.transcript);
  }
}

/// Controla el dictado por voz del composer del asistente. Es
/// `autoDispose`: al salir de la pantalla se cancela la suscripción al
/// texto reconocido y se libera el reconocedor (voiceInputSourceProvider,
/// también autoDispose).
class VoiceInputController extends Notifier<VoiceInputState> {
  StreamSubscription<String>? _transcriptSubscription;

  @override
  VoiceInputState build() {
    // ref.watch (no ref.read): mantiene vivo voiceInputSourceProvider
    // mientras este controller exista, mismo motivo que en
    // ArTryOnController con arCameraSourceProvider.
    ref.watch(voiceInputSourceProvider);
    ref.onDispose(() => _transcriptSubscription?.cancel());
    return const VoiceInputState();
  }

  Future<void> toggleListening() async {
    if (state.status == VoiceInputStatus.listening) {
      await stopListening();
      return;
    }

    final source = ref.read(voiceInputSourceProvider);
    final ready = await source.initialize();
    if (!ready) {
      state = state.copyWith(status: VoiceInputStatus.unavailable);
      return;
    }

    state = state.copyWith(status: VoiceInputStatus.listening, transcript: '');
    await _transcriptSubscription?.cancel();
    _transcriptSubscription = source.transcriptStream.listen(
      (text) => state = state.copyWith(transcript: text),
    );
    await source.startListening();
  }

  Future<void> stopListening() async {
    await ref.read(voiceInputSourceProvider).stopListening();
    state = state.copyWith(status: VoiceInputStatus.idle);
  }
}

final voiceInputControllerProvider = NotifierProvider.autoDispose<VoiceInputController, VoiceInputState>(
  VoiceInputController.new,
);
