import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';
import 'package:fashion_store/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

class SendAssistantMessageUseCase {
  final AiAssistantRepository _repository;

  const SendAssistantMessageUseCase(this._repository);

  Future<Result<AssistantMessage>> call({
    required String message,
    required List<AssistantMessage> history,
  }) {
    return _repository.sendMessage(message: message, history: history);
  }
}

final sendAssistantMessageUseCaseProvider = Provider<SendAssistantMessageUseCase>((ref) {
  return SendAssistantMessageUseCase(ref.watch(aiAssistantRepositoryProvider));
});
