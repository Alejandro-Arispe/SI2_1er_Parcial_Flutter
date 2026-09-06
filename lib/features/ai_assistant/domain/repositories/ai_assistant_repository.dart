import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';

/// Contrato del asistente inteligente (Fase 18, ver sección 14 del
/// documento): la integración con Gemini pasa siempre por el backend
/// (Flutter -> FastAPI -> Gemini API), nunca directo desde Flutter, para
/// no exponer la clave de Gemini en el cliente (sección 32).
abstract class AiAssistantRepository {
  /// Envía [message] al asistente. [history] es la conversación previa,
  /// necesaria para que el backend le dé contexto a Gemini; el mock no
  /// la usa porque no mantiene una conversación real.
  Future<Result<AssistantMessage>> sendMessage({
    required String message,
    required List<AssistantMessage> history,
  });
}
