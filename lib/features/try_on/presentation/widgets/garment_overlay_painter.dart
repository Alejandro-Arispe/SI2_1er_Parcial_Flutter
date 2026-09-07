import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:fashion_store/features/try_on/domain/entities/body_pose.dart';

/// Dibuja la imagen de la prenda posicionada, escalada y rotada sobre el
/// torso detectado (Fase 21, sección 17.2 del documento:
/// "posicionamiento de la prenda" y "renderizado"). No es una simulación
/// 3D de tela: es una superposición 2D anclada a hombros/caderas, la
/// limitación esperada de un probador AR basado en seguimiento de pose
/// en lugar de un motor de realidad aumentada completo (ver el análisis
/// de viabilidad en MlKitArCameraSource).
class GarmentOverlayPainter extends CustomPainter {
  final BodyPose pose;
  final ui.Image garmentImage;

  const GarmentOverlayPainter({required this.pose, required this.garmentImage});

  @override
  void paint(Canvas canvas, Size size) {
    // El BodyPose llega en las coordenadas del frame de la cámara
    // (pose.imageSize); acá se escala al tamaño real en el que se está
    // dibujando la vista previa en pantalla.
    final scaleX = size.width / pose.imageSize.width;
    final scaleY = size.height / pose.imageSize.height;
    Offset toScreen(Offset point) => Offset(point.dx * scaleX, point.dy * scaleY);

    final leftShoulder = toScreen(pose.leftShoulder);
    final rightShoulder = toScreen(pose.rightShoulder);
    final leftHip = toScreen(pose.leftHip);
    final rightHip = toScreen(pose.rightHip);

    final shoulderCenter = Offset.lerp(leftShoulder, rightShoulder, 0.5)!;
    final hipCenter = Offset.lerp(leftHip, rightHip, 0.5)!;
    final shoulderWidth = (rightShoulder - leftShoulder).distance;
    final torsoHeight = (hipCenter - shoulderCenter).distance;

    // Un poco más ancha que los hombros para que la prenda cubra el
    // torso en lugar de quedar ajustada exactamente a los puntos.
    final garmentWidth = shoulderWidth * 1.8;
    final aspectRatio = garmentImage.height / garmentImage.width;
    final garmentHeight = garmentWidth * aspectRatio;

    // Ángulo de la línea de hombros: así la prenda se inclina con el
    // cuerpo en lugar de quedar siempre perfectamente vertical.
    final angle = math.atan2(
      rightShoulder.dy - leftShoulder.dy,
      rightShoulder.dx - leftShoulder.dx,
    );

    canvas.save();
    canvas.translate(shoulderCenter.dx, shoulderCenter.dy + torsoHeight * 0.15);
    canvas.rotate(angle);

    final destRect = Rect.fromCenter(center: Offset.zero, width: garmentWidth, height: garmentHeight);
    final srcRect = Rect.fromLTWH(0, 0, garmentImage.width.toDouble(), garmentImage.height.toDouble());
    canvas.drawImageRect(garmentImage, srcRect, destRect, Paint()..filterQuality = FilterQuality.medium);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GarmentOverlayPainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.garmentImage != garmentImage;
  }
}
