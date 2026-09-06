import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';

class AssistantMessageModel extends AssistantMessage {
  const AssistantMessageModel({
    required super.id,
    required super.role,
    required super.content,
    required super.suggestedProducts,
    required super.createdAt,
  });

  factory AssistantMessageModel.fromJson(Map<String, dynamic> json) {
    return AssistantMessageModel(
      id: json['id'] as String,
      role: MessageRole.values.byName(json['role'] as String),
      content: json['content'] as String,
      suggestedProducts: (json['suggested_products'] as List<dynamic>)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
