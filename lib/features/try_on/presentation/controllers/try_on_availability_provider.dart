import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/features/try_on/domain/services/ar_try_on_service.dart';
import 'package:fashion_store/features/try_on/domain/services/photo_try_on_service.dart';
import 'package:fashion_store/features/try_on/domain/services/try_on_service.dart';

/// Uso real de la abstracción TryOnService (sección 17.3 del documento):
/// quien decide qué botones de probador mostrar en el detalle de
/// producto no pregunta por PhotoTryOnService ni ARTryOnService
/// directamente, solo recorre la lista de TryOnService disponibles. Esto
/// es lo que permite, por ejemplo, agregar un tercer modo más adelante
/// sin tocar la pantalla que los ofrece.
final tryOnServicesProvider = Provider<List<TryOnService>>((ref) {
  return [ref.watch(photoTryOnServiceProvider), ref.watch(arTryOnServiceProvider)];
});

/// Modos que realmente pueden usarse en este dispositivo ahora mismo
/// (por ejemplo, AR no está disponible sin una cámara física).
final availableTryOnModesProvider = FutureProvider.autoDispose<Set<TryOnMode>>((ref) async {
  final services = ref.watch(tryOnServicesProvider);
  final availability = await Future.wait(
    services.map((service) async => MapEntry(service.mode, await service.isAvailable())),
  );
  return {for (final entry in availability) if (entry.value) entry.key};
});
