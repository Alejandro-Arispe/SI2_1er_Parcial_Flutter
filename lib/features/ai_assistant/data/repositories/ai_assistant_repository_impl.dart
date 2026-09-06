import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/error/error_mapper.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/network/dio_client.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/ai_assistant/data/datasources/ai_assistant_api_data_source.dart';
import 'package:fashion_store/features/ai_assistant/data/datasources/ai_assistant_data_source.dart';
import 'package:fashion_store/features/ai_assistant/data/datasources/ai_assistant_mock_data_source.dart';
import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';
import 'package:fashion_store/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  final AiAssistantDataSource _dataSource;

  const AiAssistantRepositoryImpl(this._dataSource);

  @override
  Future<Result<AssistantMessage>> sendMessage({
    required String message,
    required List<AssistantMessage> history,
  }) async {
    try {
      return Success(await _dataSource.sendMessage(message: message, history: history));
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }
}

final aiAssistantDataSourceProvider = Provider<AiAssistantDataSource>((ref) {
  return AppConfig.useMockData
      ? AiAssistantMockDataSource(ref.watch(catalogDataSourceProvider))
      : AiAssistantApiDataSource(ref.watch(dioClientProvider));
});

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepositoryImpl(ref.watch(aiAssistantDataSourceProvider));
});
