import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:fashion_store/features/try_on/data/datasources/try_on_data_source.dart';
import 'package:fashion_store/features/try_on/data/models/try_on_result_model.dart';

/// Datasource temporal de desarrollo: no hay backend ni Gemini todavía
/// (sección 32: Flutter nunca llama a Gemini directamente), así que en
/// vez de simular con datos falsos (como el asistente o recomendaciones),
/// esta clase genera de verdad una vista previa distinta por cada foto y
/// prenda: decodifica la foto real de la clienta y compone sobre ella un
/// panel con el color de la prenda elegida (dart:ui/painting en lugar de
/// material porque es composición de imagen pura, no un widget). Esto
/// cumple con que el probador "no debe ser un mockup estático" (sección
/// 37) sin necesitar red ni una clave de IA en el cliente.
class TryOnMockDataSource implements TryOnDataSource {
  const TryOnMockDataSource();

  static const _defaultOverlayColor = ui.Color(0xFF7A2E3B);

  @override
  Future<TryOnResultModel> generate({
    required Uint8List photoBytes,
    required String productId,
    required String productName,
    String? colorHex,
  }) async {
    // Simula el tiempo de procesamiento que tomaría generar la imagen en
    // el backend real.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final composedBytes = await _composeImage(photoBytes: photoBytes, colorHex: colorHex);

    return TryOnResultModel(
      imageBytes: composedBytes,
      productId: productId,
      generatedAt: DateTime.now(),
    );
  }

  Future<Uint8List> _composeImage({required Uint8List photoBytes, String? colorHex}) async {
    final codec = await ui.instantiateImageCodec(photoBytes);
    final frame = await codec.getNextFrame();
    final photoImage = frame.image;
    final width = photoImage.width.toDouble();
    final height = photoImage.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(photoImage, Offset.zero, Paint());

    final overlayColor = _parseColor(colorHex) ?? _defaultOverlayColor;
    // Panel en la zona central-baja de la foto: representa dónde caería
    // la prenda probada sin pretender ser un render fotorrealista.
    final panelRect = Rect.fromLTWH(width * 0.12, height * 0.42, width * 0.76, height * 0.46);
    final panelRRect = RRect.fromRectAndRadius(panelRect, const Radius.circular(24));

    canvas.drawRRect(panelRRect, Paint()..color = overlayColor.withValues(alpha: 0.4));
    canvas.drawRRect(
      panelRRect,
      Paint()
        ..color = overlayColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final picture = recorder.endRecording();
    final composedImage = await picture.toImage(photoImage.width, photoImage.height);
    final byteData = await composedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  ui.Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final normalized = hex.replaceFirst('#', '');
    final withAlpha = normalized.length == 6 ? 'ff$normalized' : normalized;
    final value = int.tryParse(withAlpha, radix: 16);
    return value == null ? null : ui.Color(value);
  }
}
