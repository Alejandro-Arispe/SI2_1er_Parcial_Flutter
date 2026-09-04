/// Sucursal física de la empresa (ver sección 8 del documento: la
/// empresa tiene sucursales en diferentes ciudades del país).
class Branch {
  final String id;
  final String name;
  final String city;

  const Branch({required this.id, required this.name, required this.city});
}
