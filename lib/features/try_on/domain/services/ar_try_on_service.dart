import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/features/try_on/data/services/ar_camera_source.dart';
import 'package:fashion_store/features/try_on/data/services/mlkit_ar_camera_source.dart';
import 'package:fashion_store/features/try_on/domain/services/try_on_service.dart';

/// Rama "cámara/AR" de TryOnService (Fase 21, sección 17.2 del
/// documento). El seguimiento en vivo en sí lo maneja ArTryOnController
/// junto con ArCameraSource; esta clase solo expone el modo y su
/// disponibilidad real (requiere una cámara física), para que quien
/// decida qué modos ofrecer no dependa de ArCameraSource directamente.
class ARTryOnService implements TryOnService {
  final ArCameraSource _cameraSource;

  const ARTryOnService(this._cameraSource);

  @override
  TryOnMode get mode => TryOnMode.ar;

  @override
  Future<bool> isAvailable() => _cameraSource.isAvailable();
}

final arTryOnServiceProvider = Provider<TryOnService>((ref) {
  return ARTryOnService(ref.watch(arCameraSourceProvider));
});
