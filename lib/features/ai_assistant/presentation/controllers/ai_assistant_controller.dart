import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';
import 'package:fashion_store/features/ai_assistant/domain/usecases/send_assistant_message_usecase.dart';

class AiAssistantState {
  final List<AssistantMessage> messages;
  final bool isSending;
  final Failure? error;

  const AiAssistantState({required this.messages, required this.isSending, required this.error});

  factory AiAssistantState.initial() => AiAssistantState(
        messages: [
          AssistantMessage(
            id: 'assistant-greeting',
            role: MessageRole.assistant,
            content: 'Hola, soy el asistente de FashionStore. Puedo ayudarte a encontrar '
                'prendas, combinar un look o resolver dudas sobre el catálogo. '
                '¿En qué te ayudo hoy?',
            suggestedProducts: const [],
            createdAt: DateTime.now(),
          ),
        ],
        isSending: false,
        error: null,
      );
}

/// Controller del asistente inteligente (Fase 18): mantiene la
/// conversación y delega cada mensaje al backend, que es quien habla
/// con Gemini (ver sección 14 del documento). El mensaje de bienvenida
/// inicial es local, no requiere una llamada real.
class AiAssistantController extends Notifier<AiAssistantState> {
  @override
  AiAssistantState build() => AiAssistantState.initial();

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = AssistantMessage(
      id: 'user-message-${DateTime.now().microsecondsSinceEpoch}',
      role: MessageRole.user,
      content: trimmed,
      suggestedProducts: const [],
      createdAt: DateTime.now(),
    );
    final historyBeforeReply = [...state.messages, userMessage];
    state = AiAssistantState(messages: historyBeforeReply, isSending: true, error: null);

    final result = await ref.read(sendAssistantMessageUseCaseProvider).call(
          message: trimmed,
          history: state.messages,
        );

    switch (result) {
      case Success(:final data):
        state = AiAssistantState(messages: [...historyBeforeReply, data], isSending: false, error: null);
      case ResultError(:final failure):
        state = AiAssistantState(messages: historyBeforeReply, isSending: false, error: failure);
    }
  }
}

final aiAssistantControllerProvider = NotifierProvider<AiAssistantController, AiAssistantState>(
  AiAssistantController.new,
);
