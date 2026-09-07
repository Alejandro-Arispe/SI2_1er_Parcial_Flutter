import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/features/try_on/domain/services/try_on_service.dart';

/// Rama "foto" de TryOnService (Fase 20, sección 17.1 del documento). La
/// generación en sí ya vive en TryOnRepository/GenerateTryOnUseCase; esta
/// clase solo expone el modo y su disponibilidad para que quien decida
/// qué modos ofrecer no dependa de esos tipos concretos.
class PhotoTryOnService implements TryOnService {
  const PhotoTryOnService();

  @override
  TryOnMode get mode => TryOnMode.photo;

  @override
  Future<bool> isAvailable() async => true;
}

final photoTryOnServiceProvider = Provider<TryOnService>((ref) {
  return const PhotoTryOnService();
});
