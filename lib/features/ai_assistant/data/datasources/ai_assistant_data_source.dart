import 'package:fashion_store/features/ai_assistant/data/models/assistant_message_model.dart';
import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';

/// Contrato común para las fuentes de datos del asistente. Dos
/// implementaciones intercambiables: AiAssistantApiDataSource (real,
/// contra FastAPI, que a su vez llama a Gemini) y
/// AiAssistantMockDataSource (temporal, datos de desarrollo).
abstract class AiAssistantDataSource {
  Future<AssistantMessageModel> sendMessage({
    required String message,
    required List<AssistantMessage> history,
  });
}
