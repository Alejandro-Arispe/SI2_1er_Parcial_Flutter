import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/try_on/data/services/mlkit_ar_camera_source.dart';
import 'package:fashion_store/features/try_on/domain/entities/body_pose.dart';

/// Estados del flujo del probador AR (sección 33 del documento: la app
/// debe manejar explícitamente error de cámara y permiso de cámara
/// rechazado, no solo el camino feliz).
enum ArTryOnStatus {
  idle,
  checkingAvailability,
  unavailable,
  requestingPermission,
  permissionDenied,
  starting,
  tracking,
  cameraError,
}

class ArTryOnState {
  final ArTryOnStatus status;
  final Product? product;
  final ui.Image? garmentImage;
  final BodyPose? pose;

  const ArTryOnState({
    this.status = ArTryOnStatus.idle,
    this.product,
    this.garmentImage,
    this.pose,
  });

  ArTryOnState copyWith({
    ArTryOnStatus? status,
    Product? product,
    ui.Image? garmentImage,
    BodyPose? pose,
    bool clearPose = false,
  }) {
    return ArTryOnState(
      status: status ?? this.status,
      product: product ?? this.product,
      garmentImage: garmentImage ?? this.garmentImage,
      pose: clearPose ? null : (pose ?? this.pose),
    );
  }
}

/// Controla el flujo del probador por cámara/AR (Fase 21, sección 17.2
/// del documento): revisa disponibilidad de cámara, pide permiso, inicia
/// el seguimiento en vivo y mantiene la prenda que se está superponiendo.
/// Es `autoDispose`: al salir de la pantalla se cancela la suscripción al
/// stream de poses (la cámara y el detector los libera por su cuenta
/// arCameraSourceProvider, también autoDispose).
class ArTryOnController extends Notifier<ArTryOnState> {
  StreamSubscription<BodyPose?>? _poseSubscription;

  @override
  ArTryOnState build() {
    // ref.watch (no ref.read) es a propósito: arCameraSourceProvider
    // también es autoDispose, así que sin un watch activo se liberaría
    // apenas se lea una vez, antes de que la cámara llegue a usarse.
    ref.watch(arCameraSourceProvider);
    ref.onDispose(() => _poseSubscription?.cancel());
    return const ArTryOnState();
  }

  /// Controlador de cámara real para la vista previa en pantalla. Es
  /// null antes de iniciar el seguimiento o si la fuente activa no tiene
  /// una cámara física que mostrar (por ejemplo, el fake de los tests).
  CameraController? get previewController => ref.read(arCameraSourceProvider).previewController;

  void selectProduct(Product product) {
    state = state.copyWith(product: product);
    unawaited(_loadGarmentImage(product.imageUrl));
  }

  Future<void> _loadGarmentImage(String url) async {
    final completer = Completer<ui.Image>();
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        completer.completeError(error, stackTrace);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);

    try {
      final image = await completer.future;
      state = state.copyWith(garmentImage: image);
    } catch (_) {
      // Si la imagen de la prenda no carga, se sigue mostrando la
      // cámara sin superposición en vez de romper todo el probador.
    }
  }

  /// Revisa disponibilidad, pide permiso e inicia la cámara y el
  /// seguimiento en vivo. Se llama una vez al entrar a la pantalla.
  Future<void> start() async {
    final source = ref.read(arCameraSourceProvider);

    state = state.copyWith(status: ArTryOnStatus.checkingAvailability);
    final available = await source.isAvailable();
    if (!available) {
      state = state.copyWith(status: ArTryOnStatus.unavailable);
      return;
    }

    state = state.copyWith(status: ArTryOnStatus.requestingPermission);
    final granted = await source.requestPermission();
    if (!granted) {
      state = state.copyWith(status: ArTryOnStatus.permissionDenied);
      return;
    }

    state = state.copyWith(status: ArTryOnStatus.starting);
    try {
      await source.start();
    } catch (_) {
      state = state.copyWith(status: ArTryOnStatus.cameraError);
      return;
    }

    state = state.copyWith(status: ArTryOnStatus.tracking);
    await _poseSubscription?.cancel();
    _poseSubscription = source.poseStream.listen(
      (pose) => state = state.copyWith(pose: pose, clearPose: pose == null),
    );
  }

  Future<void> openSettings() => ref.read(arCameraSourceProvider).openSettings();
}

final arTryOnControllerProvider = NotifierProvider.autoDispose<ArTryOnController, ArTryOnState>(
  ArTryOnController.new,
);
