import 'package:fashion_store/features/ai_assistant/data/datasources/ai_assistant_data_source.dart';
import 'package:fashion_store/features/ai_assistant/data/models/assistant_message_model.dart';
import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';
import 'package:fashion_store/features/catalog/data/datasources/catalog_data_source.dart';
import 'package:fashion_store/features/catalog/data/models/category_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';

/// Palabras clave en español por categoría, usadas para detectar de qué
/// tipo de prenda habla la clienta. No hay procesamiento de lenguaje
/// natural real en el mock (eso lo hace Gemini en el backend real): esto
/// es solo una coincidencia de texto simple para poder mostrar
/// sugerencias razonables mientras no hay backend.
const _categoryKeywords = {
  'Vestidos': ['vestido'],
  'Blusas': ['blusa', 'camisa'],
  'Pantalones': ['pantalon', 'pantalón'],
  'Faldas': ['falda'],
  'Chaquetas': ['chaqueta'],
  'Zapatos': ['zapato', 'zapatilla', 'sandalia', 'bota', 'calzado'],
};

/// Datasource temporal de desarrollo: simula al asistente sin conectarse
/// a ningún servicio de IA (ver sección 42 del documento del proyecto).
/// Las sugerencias siempre salen del catálogo real (nunca se inventan
/// productos, ver sección 15), reutilizando CatalogDataSource en lugar
/// de duplicar datos de producto.
class AiAssistantMockDataSource implements AiAssistantDataSource {
  final CatalogDataSource _catalogDataSource;
  static int _nextId = 1;

  AiAssistantMockDataSource(this._catalogDataSource);

  @override
  Future<AssistantMessageModel> sendMessage({
    required String message,
    required List<AssistantMessage> history,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final normalized = message.toLowerCase();
    final categories = await _catalogDataSource.getCategories();
    final matchedCategory = _matchCategory(categories, normalized);

    final products = matchedCategory != null
        ? await _catalogDataSource.getProducts(
            page: 1,
            pageSize: 4,
            categoryId: matchedCategory.id,
            onlyAvailable: true,
          )
        : await _catalogDataSource.getFeaturedProducts();

    return AssistantMessageModel(
      id: 'assistant-message-${_nextId++}',
      role: MessageRole.assistant,
      content: _buildReply(matchedCategory, products),
      suggestedProducts: products.take(3).toList(),
      createdAt: DateTime.now(),
    );
  }

  CategoryModel? _matchCategory(List<CategoryModel> categories, String normalizedMessage) {
    for (final category in categories) {
      final keywords = _categoryKeywords[category.name];
      if (keywords == null) continue;
      if (keywords.any(normalizedMessage.contains)) return category;
    }
    return null;
  }

  String _buildReply(CategoryModel? matchedCategory, List<ProductModel> products) {
    if (products.isEmpty) {
      return 'No encontré prendas disponibles para mostrarte en este momento. '
          'Intenta preguntarme por otra categoría, como vestidos, blusas o zapatos.';
    }
    if (matchedCategory != null) {
      return 'Estas son algunas prendas de ${matchedCategory.name} disponibles en el catálogo '
          'que podrían interesarte:';
    }
    return 'Puedo ayudarte a encontrar prendas del catálogo. Cuéntame qué buscas '
        '(por ejemplo, un vestido, una chaqueta o zapatos) y te muestro opciones '
        'disponibles. Mientras tanto, esto es parte de lo más destacado:';
  }
}
