import 'dart:ui';

/// Puntos corporales mínimos necesarios para posicionar la prenda sobre
/// la persona en el probador por cámara/AR (Fase 21, sección 17.2 del
/// documento: "seguimiento corporal" y "posicionamiento de la prenda").
///
/// No es un modelo genérico de los 33 puntos que entrega ML Kit: el
/// dominio solo conoce los 4 puntos que en verdad usa (hombros y
/// caderas, suficientes para ubicar, escalar y rotar la prenda sobre el
/// torso), para no acoplar el resto de la app al tipo `Pose` de
/// google_mlkit_pose_detection.
///
/// Las coordenadas están en el espacio del frame ya orientado "hacia
/// arriba" (ver MlKitArCameraSource, que compensa la rotación del sensor
/// antes de exponer este objeto), con [imageSize] como referencia para
/// convertirlas a las coordenadas del preview en pantalla.
class BodyPose {
  final Offset leftShoulder;
  final Offset rightShoulder;
  final Offset leftHip;
  final Offset rightHip;
  final Size imageSize;

  const BodyPose({
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftHip,
    required this.rightHip,
    required this.imageSize,
  });
}
