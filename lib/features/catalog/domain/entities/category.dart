/// Categoría de moda femenina (vestidos, blusas, pantalones, etc.), ver
/// sección 6 del documento del proyecto: el catálogo es exclusivamente
/// de moda femenina.
class Category {
  final String id;
  final String name;
  final String imageUrl;

  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
}
