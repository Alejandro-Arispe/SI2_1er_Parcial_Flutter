import 'package:fashion_store/features/catalog/domain/entities/branch.dart';

/// Disponibilidad de una variante concreta (producto + talla + color)
/// en una sucursal (ver sección 8: el cliente debe poder saber dónde
/// está disponible una prenda). La app móvil no administra el
/// inventario, solo consulta lo que expone el backend.
class BranchStock {
  final Branch branch;
  final bool isAvailable;
  final int stock;

  const BranchStock({required this.branch, required this.isAvailable, required this.stock});
}
