import 'package:dio/dio.dart';
import 'package:fashion_store/core/network/api_endpoints.dart';
import 'package:fashion_store/features/ai_assistant/data/datasources/ai_assistant_data_source.dart';
import 'package:fashion_store/features/ai_assistant/data/models/assistant_message_model.dart';
import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';

/// Implementación real: envía el mensaje a FastAPI, que es quien arma el
/// contexto real del catálogo y llama a Gemini (ver sección 14 del
/// documento: la integración con Gemini nunca es directa desde Flutter).
class AiAssistantApiDataSource implements AiAssistantDataSource {
  final Dio _dio;

  const AiAssistantApiDataSource(this._dio);

  @override
  Future<AssistantMessageModel> sendMessage({
    required String message,
    required List<AssistantMessage> history,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.assistantMessages,
      data: {
        'message': message,
        'history': history
            .map((entry) => {'role': entry.role.name, 'content': entry.content})
            .toList(),
      },
    );
    return AssistantMessageModel.fromJson(response.data!);
  }
}
