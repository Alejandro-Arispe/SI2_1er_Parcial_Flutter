import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fashion_store/features/try_on/data/services/ar_camera_source.dart';
import 'package:fashion_store/features/try_on/domain/entities/body_pose.dart';

/// Implementación real del probador AR (Fase 21, secciones 17.2 y 39 del
/// documento). Usa `camera` para acceder a la cámara del dispositivo y
/// `google_mlkit_pose_detection` (ML Kit, on-device, sin conexión) para
/// el seguimiento corporal en tiempo real.
///
/// Justificación de la elección (sección 39: analizar viabilidad antes
/// de acoplar una librería concreta):
/// - `camera` es el plugin oficial del equipo de Flutter, mantenido
///   activamente y con soporte real en Android (a través de CameraX)
///   para vista previa en vivo y stream de frames, que es justo lo que
///   necesita este flujo.
/// - `google_mlkit_pose_detection` corre el modelo de ML Kit en el
///   propio dispositivo (no depende de red ni de Gemini en cada frame,
///   cumpliendo la sección 37: "no tratar Gemini como motor de AR en
///   tiempo real"), es gratuito, funciona offline y da 33 puntos
///   corporales con buen rendimiento en hardware Android típico.
/// - Alternativas como ARCore/Sceneform no tienen un wrapper Flutter
///   viable y activamente mantenido hoy, y construir un modelo propio
///   (por ejemplo con TensorFlow Lite) excede el alcance y el tiempo de
///   un proyecto académico. Por eso se descartaron.
/// - Limitación conocida y aceptada: no hay simulación 3D de tela, solo
///   posicionamiento 2D de la imagen de la prenda sobre el torso
///   detectado (hombros/caderas). Es la limitación típica de un MVP de
///   probador AR y sigue siendo un flujo funcional en vivo, no una
///   imagen estática (sección 17, sección 37 "NO HACER").
class MlKitArCameraSource implements ArCameraSource {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  final _poseStreamController = StreamController<BodyPose?>.broadcast();
  bool _isProcessingFrame = false;
  List<CameraDescription>? _camerasCache;

  static const _minLandmarkLikelihood = 0.5;

  // Compensación de rotación del sensor de cámara (ver el ejemplo
  // oficial de google_mlkit_pose_detection). Se asume el dispositivo en
  // orientación portrait: es como se usa el resto de la app (sección 29,
  // "diseñar correctamente para teléfonos") y evita sumar una
  // dependencia solo para leer la orientación real del dispositivo
  // (sección 37: no crear dependencias innecesarias).
  static const _deviceOrientation = DeviceOrientation.portraitUp;
  static const _orientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  CameraController? get previewController => _controller;

  @override
  Stream<BodyPose?> get poseStream => _poseStreamController.stream;

  @override
  Future<bool> isAvailable() async {
    try {
      _camerasCache ??= await availableCameras();
      return _camerasCache!.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<void> openSettings() => openAppSettings();

  @override
  Future<void> start() async {
    final cameras = _camerasCache ?? await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No hay una cámara disponible en este dispositivo.');
    }

    // Cámara frontal preferida: el probador se usa "sobre sí misma"
    // (selfie, sección 17.2). Si el dispositivo no tiene frontal, se usa
    // la primera disponible.
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _poseDetector ??= PoseDetector(
      options: PoseDetectorOptions(model: PoseDetectionModel.base, mode: PoseDetectionMode.stream),
    );

    final controller = CameraController(
      camera,
      // "medium" alcanza para detectar puntos corporales sin saturar el
      // procesamiento de cada frame (sección 39: rendimiento como
      // criterio de viabilidad); no hace falta resolución máxima.
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    _controller = controller;

    await controller.initialize();
    await controller.startImageStream(_onFrame);
  }

  void _onFrame(CameraImage image) {
    // Si el frame anterior todavía se está procesando, se descarta este
    // en lugar de encolarlo: mantiene el seguimiento en tiempo real sin
    // acumular retraso frame tras frame.
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;
    _processFrame(image).whenComplete(() => _isProcessingFrame = false);
  }

  Future<void> _processFrame(CameraImage image) async {
    final controller = _controller;
    final detector = _poseDetector;
    if (controller == null || detector == null) return;

    final inputImage = _toInputImage(image, controller.description);
    if (inputImage == null) return;

    try {
      final poses = await detector.processImage(inputImage);
      if (_poseStreamController.isClosed) return;

      if (poses.isEmpty) {
        _poseStreamController.add(null);
        return;
      }

      final rawSize = inputImage.metadata!.size;
      final sideways = _isSideways(inputImage.metadata!.rotation);
      final uprightSize = sideways ? Size(rawSize.height, rawSize.width) : rawSize;
      final mirror = controller.description.lensDirection == CameraLensDirection.front;

      _poseStreamController.add(_toBodyPose(poses.first, uprightSize, mirror));
    } catch (_) {
      // Un frame fallido no debe cortar el flujo en vivo: se ignora y se
      // sigue procesando el siguiente.
    }
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    var rotationCompensation = _orientationDegrees[_deviceOrientation]!;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
    }
    final rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    if (rotation == null) return null;

    final nv21Bytes = _toNv21(image);
    if (nv21Bytes == null) return null;

    return InputImage.fromBytes(
      bytes: nv21Bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  /// Convierte el frame de la cámara a NV21, el formato de un solo plano
  /// que espera ML Kit en Android. Según el dispositivo, `camera` puede
  /// entregar el frame ya en un solo plano o como YUV_420_888 en tres
  /// planos separados (Y, U, V); en ese segundo caso hay que
  /// reconstruir manualmente el entrelazado V/U que pide NV21.
  Uint8List? _toNv21(CameraImage image) {
    if (image.planes.length == 1) {
      return image.planes.first.bytes;
    }
    if (image.planes.length != 3) return null;

    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final nv21 = Uint8List(width * height + (width * height) ~/ 2);

    // Plano Y: se copia fila por fila respetando bytesPerRow, que puede
    // ser mayor al ancho real de la imagen (padding propio de la cámara).
    var offset = 0;
    for (var row = 0; row < height; row++) {
      final rowStart = row * yPlane.bytesPerRow;
      nv21.setRange(offset, offset + width, yPlane.bytes, rowStart);
      offset += width;
    }

    // Planos U/V: Android los entrega separados; NV21 los necesita
    // intercalados como V,U. Se reconstruye manualmente en lugar de
    // asumir que ya vienen entrelazados.
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < height ~/ 2; row++) {
      for (var col = 0; col < width ~/ 2; col++) {
        final uvIndex = row * uPlane.bytesPerRow + col * uvPixelStride;
        nv21[offset++] = vPlane.bytes[uvIndex];
        nv21[offset++] = uPlane.bytes[uvIndex];
      }
    }

    return nv21;
  }

  bool _isSideways(InputImageRotation rotation) {
    return rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
  }

  /// Arma el BodyPose de dominio a partir de la pose cruda de ML Kit.
  /// Sin los 4 puntos del torso con una confianza mínima no hay dónde
  /// ubicar la prenda, así que se descarta el frame en lugar de mostrar
  /// una prenda mal posicionada.
  BodyPose? _toBodyPose(Pose pose, Size uprightSize, bool mirror) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
      return null;
    }
    final points = [leftShoulder, rightShoulder, leftHip, rightHip];
    if (points.any((point) => point.likelihood < _minLandmarkLikelihood)) {
      return null;
    }

    // La cámara frontal se muestra reflejada en la vista previa (como un
    // espejo), pero el frame crudo que procesa ML Kit no lo está: se
    // refleja aquí el eje X para que la prenda quede alineada con lo que
    // la clienta ve en pantalla.
    Offset toOffset(PoseLandmark landmark) {
      final x = mirror ? uprightSize.width - landmark.x : landmark.x;
      return Offset(x, landmark.y);
    }

    return BodyPose(
      leftShoulder: toOffset(leftShoulder),
      rightShoulder: toOffset(rightShoulder),
      leftHip: toOffset(leftHip),
      rightHip: toOffset(rightHip),
      imageSize: uprightSize,
    );
  }

  @override
  Future<void> stop() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.dispose();
    _controller = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _poseDetector?.close();
    _poseDetector = null;
    await _poseStreamController.close();
  }
}

final arCameraSourceProvider = Provider.autoDispose<ArCameraSource>((ref) {
  final source = MlKitArCameraSource();
  // El dueño del recurso es este provider, no quien lo consume: se
  // libera la cámara y el detector apenas deja de observarse (al salir
  // de la pantalla del probador AR), sin depender de que el widget se
  // acuerde de hacerlo.
  ref.onDispose(() => source.dispose());
  return source;
});
