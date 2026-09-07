import 'package:camera/camera.dart';
import 'package:fashion_store/features/try_on/domain/entities/body_pose.dart';

/// Motor de cámara + seguimiento corporal para el probador AR (Fase 21,
/// secciones 17.2 y 17.3 del documento).
///
/// Se define como interfaz separada de ARTryOnService a propósito: es el
/// punto exacto que la sección 17.3 pide poder cambiar sin tocar el
/// resto de la app ("esto permitirá cambiar posteriormente el motor de
/// AR"). Hoy la única implementación real es MlKitArCameraSource (camera
/// + google_mlkit_pose_detection); en los tests se reemplaza por un fake
/// inyectado vía ProviderScope, igual que se hace con
/// SecureStorageService, para no depender de plugins de plataforma que
/// no funcionan en el entorno de pruebas.
abstract class ArCameraSource {
  /// Si el dispositivo tiene al menos una cámara física real.
  Future<bool> isAvailable();

  /// Pide el permiso de cámara al sistema operativo (sección 34 del
  /// documento: los permisos deben pedirse solo cuando son necesarios,
  /// justo antes de usar la cámara, no al abrir la app).
  Future<bool> requestPermission();

  /// Abre la pantalla de configuración de la app, para cuando la clienta
  /// rechazó el permiso de cámara y quiere concederlo manualmente.
  Future<void> openSettings();

  /// Controlador de la cámara real para renderizar la vista previa en
  /// pantalla con CameraPreview. Es null en implementaciones que no
  /// tienen una cámara física que mostrar (por ejemplo, el fake usado en
  /// los tests de widgets).
  CameraController? get previewController;

  /// Emite la pose detectada en cada frame procesado, o null cuando no
  /// se detecta a nadie frente a la cámara. Es un stream (no un valor
  /// único) porque el seguimiento corporal debe actualizarse en tiempo
  /// real mientras la clienta se mueve (sección 17.2: "actualización de
  /// la visualización").
  Stream<BodyPose?> get poseStream;

  /// Abre la cámara y comienza a procesar frames. Debe llamarse después
  /// de requestPermission().
  Future<void> start();

  /// Detiene el procesamiento de frames y libera la cámara, pero deja el
  /// detector listo para volver a iniciar con start().
  Future<void> stop();

  /// Libera todos los recursos de forma definitiva (se llama al salir de
  /// la pantalla del probador AR).
  Future<void> dispose();
}
