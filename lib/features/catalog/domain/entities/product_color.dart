/// Color de una variante de producto. `hexValue` permite pintar un
/// pequeño círculo de color en la UI sin depender de una imagen extra.
class ProductColor {
  final String id;
  final String name;
  final String hexValue;

  const ProductColor({required this.id, required this.name, required this.hexValue});
}
