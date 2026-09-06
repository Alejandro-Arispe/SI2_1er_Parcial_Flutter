import 'package:fashion_store/features/catalog/domain/entities/product.dart';

/// Quién escribió un mensaje de la conversación con el asistente.
enum MessageRole { user, assistant }

/// Un mensaje de la conversación con el asistente inteligente (Fase 18,
/// ver sección 15 del documento del proyecto). Los mensajes del
/// asistente pueden traer prendas reales del catálogo como sugerencia
/// (sección 15: "la IA no debe inventar productos"); nunca se muestran
/// productos que no existan en el catálogo.
class AssistantMessage {
  final String id;
  final MessageRole role;
  final String content;
  final List<Product> suggestedProducts;
  final DateTime createdAt;

  const AssistantMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.suggestedProducts,
    required this.createdAt,
  });
}
