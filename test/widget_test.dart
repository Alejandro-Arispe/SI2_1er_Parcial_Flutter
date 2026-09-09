import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fashion_store/app/app.dart';
import 'package:fashion_store/core/network/connectivity_service.dart';
import 'package:fashion_store/core/security/secure_storage_service.dart';
import 'package:fashion_store/core/voice/flutter_tts_voice_output_source.dart';
import 'package:fashion_store/core/voice/speech_to_text_voice_input_source.dart';
import 'package:fashion_store/core/voice/voice_input_source.dart';
import 'package:fashion_store/core/voice/voice_output_source.dart';
import 'package:fashion_store/features/recommendations/presentation/controllers/recently_viewed_controller.dart';
import 'package:fashion_store/features/try_on/data/services/ar_camera_source.dart';
import 'package:fashion_store/features/try_on/data/services/mlkit_ar_camera_source.dart';
import 'package:fashion_store/features/try_on/domain/entities/body_pose.dart';
import 'package:fashion_store/shared/session/authenticated_user.dart';
import 'package:fashion_store/shared/session/session_controller.dart';

/// Fake de almacenamiento seguro para pruebas de widgets.
///
/// SecureStorageService real usa flutter_secure_storage, que depende de
/// un canal de plataforma (Android Keystore). En un test de widgets sin
/// dispositivo real ese canal nunca responde, así que se sobreescribe el
/// provider con este fake para no depender de la plataforma.
class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(const FlutterSecureStorage());

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<Map<String, String>?> readUserProfile() async => null;
}

/// Fake de ConnectivityService (Fase 23): empieza "en línea" para que
/// los flujos críticos (checkout, pago, reserva) se comporten como antes
/// de esta fase, pero permite alternar el estado desde el test
/// (setOnline) para probar el aviso de sin conexión. connectivity_plus
/// depende de un canal de plataforma que no existe en el entorno de
/// test.
class _FakeConnectivityService extends ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  bool _online = true;

  void setOnline(bool value) {
    _online = value;
    _controller.add(value);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;
}

/// Imagen PNG transparente de 1x1, usada como respuesta falsa para
/// cualquier petición de red durante los tests (Home carga imágenes de
/// producto/categoría vía CachedNetworkImage). Evita depender de una
/// librería externa de mocking solo para esto.
final _transparentPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse(_transparentPng);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> _bytes;
  _FakeHttpClientResponse(this._bytes);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Fake de la plataforma de image_picker (Fase 20): en el entorno de test
/// no hay cámara ni selector de archivos real, así que ambas fuentes
/// responden con la misma imagen PNG válida usada para las respuestas de
/// red (_transparentPng), suficiente para que TryOnMockDataSource pueda
/// decodificarla y componer la vista previa.
class _FakeImagePickerPlatform extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile.fromData(_transparentPng, name: 'photo.png', mimeType: 'image/png');
  }
}

/// Fake de ArCameraSource (Fase 21): en el entorno de test no hay una
/// cámara real ni el plugin de ML Kit disponible, así que se simula un
/// cuerpo detectado sin depender de ninguno de los dos. previewController
/// queda en null a propósito (no hay CameraController real que crear),
/// lo que ejercita el mismo camino de "vista previa no disponible" que
/// vería un dispositivo sin cámara.
class _FakeArCameraSource implements ArCameraSource {
  final _poseController = StreamController<BodyPose?>.broadcast();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> openSettings() async {}

  @override
  CameraController? get previewController => null;

  @override
  Stream<BodyPose?> get poseStream => _poseController.stream;

  @override
  Future<void> start() async {
    // Se agenda con un delay real (no inmediato) para que la pose llegue
    // recién después de que ArTryOnController alcance a suscribirse al
    // stream (el controller escucha poseStream justo después de este
    // await start(), no antes).
    Future<void>.delayed(const Duration(milliseconds: 10), () {
      if (!_poseController.isClosed) {
        _poseController.add(
          const BodyPose(
            leftShoulder: Offset(20, 40),
            rightShoulder: Offset(80, 40),
            leftHip: Offset(25, 120),
            rightHip: Offset(75, 120),
            imageSize: Size(100, 200),
          ),
        );
      }
    });
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _poseController.close();
  }
}

/// Fake de VoiceInputSource (Fase 22): en el entorno de test no hay
/// reconocimiento de voz real disponible, así que se simula una
/// transcripción fija apenas se empieza a "escuchar".
class _FakeVoiceInputSource implements VoiceInputSource {
  final _transcriptController = StreamController<String>.broadcast();
  bool _listening = false;

  @override
  Future<bool> initialize() async => true;

  @override
  bool get isListening => _listening;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Future<void> startListening() async {
    _listening = true;
    // Delay real (no inmediato) para que el texto llegue después de que
    // VoiceInputController ya se suscribió al stream.
    Future<void>.delayed(const Duration(milliseconds: 10), () {
      if (!_transcriptController.isClosed) {
        _transcriptController.add('Quiero un vestido para una fiesta');
      }
    });
  }

  @override
  Future<void> stopListening() async => _listening = false;

  @override
  Future<void> dispose() async => _transcriptController.close();
}

/// Fake de VoiceOutputSource (Fase 22): no hay motor de texto a voz
/// real en el entorno de test, así que no hace nada observable; solo
/// existe para que tocar "Escuchar respuesta" no intente usar el plugin
/// real de flutter_tts durante las pruebas.
class _FakeVoiceOutputSource implements VoiceOutputSource {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('La app arranca en splash y redirige a Home sin sesión', (WidgetTester tester) async {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform();
    // shared_preferences (Fase 23) también depende de un canal de
    // plataforma; esto habilita su respaldo en memoria para los tests.
    SharedPreferences.setMockInitialValues({});
    final fakeConnectivity = _FakeConnectivityService();

    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              secureStorageServiceProvider.overrideWithValue(_FakeSecureStorageService()),
              arCameraSourceProvider.overrideWithValue(_FakeArCameraSource()),
              voiceInputSourceProvider.overrideWithValue(_FakeVoiceInputSource()),
              voiceOutputSourceProvider.overrideWithValue(_FakeVoiceOutputSource()),
              connectivityServiceProvider.overrideWithValue(fakeConnectivity),
            ],
            child: const FashionStoreApp(),
          ),
        );

        // Primer frame: mientras SessionController resuelve la sesión guardada.
        expect(find.text('FashionStore'), findsOneWidget);

        // Dos pumps: uno para procesar el resultado de _restoreSession y otro
        // para que GoRouter reaccione al cambio de estado de sesión.
        await tester.pump();
        await tester.pump();

        // Aparece en la etiqueta de la barra de navegación inferior.
        expect(find.text('Home'), findsWidgets);

        // El controller de Home consulta el catálogo mock, que simula
        // latencia de red (~500ms por llamada, dos llamadas secuenciales).
        // Se espera ese tiempo para que no queden timers pendientes al
        // terminar el test y para verificar que el contenido real carga.
        await tester.pump(const Duration(milliseconds: 1200));

        expect(find.text('Destacados'), findsOneWidget);

        // Fase 12: favoritos. Sin sesión, tocar el corazón debe llevar
        // a login en lugar de guardar el favorito (ver sección 21).
        final favoriteButtonFinder = find.byIcon(Icons.favorite_border).first;
        await tester.tap(favoriteButtonFinder);
        await tester.pump();

        expect(find.widgetWithText(AppBar, 'Iniciar sesión'), findsOneWidget);

        // El formulario de login ya se probó en la Fase 5; aquí solo
        // interesa tener una sesión activa para seguir probando
        // favoritos, así que se autentica directamente a través del
        // contenedor de providers en lugar de rellenar el formulario.
        final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
        container.read(sessionControllerProvider.notifier).markAuthenticated(
              const AuthenticatedUser(id: 'test-user', name: 'Maria', email: 'maria@example.com'),
            );
        await tester.pump();
        await tester.pump();

        // Al quedar autenticada mientras está en /login, el router
        // redirige automáticamente a Home.
        expect(find.text('Destacados'), findsOneWidget);

        // Ahora con sesión, marcar como favorito sí debe funcionar
        // (actualización optimista: el ícono cambia sin esperar red).
        await tester.tap(find.byIcon(Icons.favorite_border).first);
        await tester.pump();

        expect(find.byIcon(Icons.favorite), findsWidgets);

        // Se espera la llamada real de guardado (~300ms) para no dejar
        // timers pendientes al terminar el test.
        await tester.pump(const Duration(milliseconds: 400));

        // El producto marcado debe aparecer en la pestaña Favoritos.
        await tester.tap(find.text('Favoritos').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.text('Vestido Floral'), findsWidgets);

        // Vuelve a Home para continuar con el resto del recorrido
        // (catálogo, búsqueda, detalle) igual que antes de la Fase 12.
        await tester.tap(find.text('Home').first);
        await tester.pump();

        // Navega a la pestaña Catálogo (Fase 7) y espera su carga inicial
        // (categorías + primera página de productos, cada una con la
        // misma latencia simulada que Home).
        await tester.tap(find.text('Catálogo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1200));

        expect(find.text('Todas'), findsOneWidget);
        expect(find.text('Vestido Floral'), findsWidgets);

        // Fase 8: la búsqueda por texto filtra el listado. Se escribe en
        // el campo de búsqueda y se espera el debounce (400ms) más la
        // latencia simulada del mock (500ms) antes de revisar el filtro.
        await tester.enterText(find.byType(TextField), 'Zapatillas');
        await tester.pump(const Duration(milliseconds: 900));

        expect(find.text('Zapatillas Urbanas'), findsWidgets);
        expect(find.text('Vestido Floral'), findsNothing);

        // Fase 9: tocar el producto abre el detalle con su descripción.
        final productFinder = find.text('Zapatillas Urbanas').first;
        await tester.ensureVisible(productFinder);
        await tester.pump();
        await tester.tap(productFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // La galería de imágenes a ancho completo es más alta que el
        // viewport del test, así que hay que desplazarse para que la
        // descripción quede dentro del árbol de widgets construido. Se
        // arrastra en pasos y se repite hasta encontrarla en lugar de un
        // único desplazamiento fijo, porque el viewport disponible
        // cambia según la pantalla (por ejemplo, al agregar la barra de
        // "Agregar al carrito" en la Fase 13).
        for (var i = 0; i < 6 && find.text('Descripción').evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump();
        }

        expect(find.text('Descripción'), findsOneWidget);
        expect(find.textContaining('Zapatillas Urbanas es una prenda'), findsOneWidget);

        // Fase 10: seleccionar talla y color revela la disponibilidad
        // de esa variante concreta (antes solo se muestra un mensaje
        // pidiendo elegir ambas).
        expect(find.text('Selecciona talla y color para ver disponibilidad.'), findsOneWidget);

        final sizeChipFinder = find.widgetWithText(ChoiceChip, 'S');
        await tester.ensureVisible(sizeChipFinder);
        await tester.pump();
        await tester.tap(sizeChipFinder);
        await tester.pump();

        const colorNames = ['Negro', 'Blanco', 'Rojo', 'Azul', 'Beige', 'Verde'];
        final colorSwatchFinder = find.byWidgetPredicate(
          (widget) => widget is Tooltip && colorNames.contains(widget.message),
        );
        await tester.ensureVisible(colorSwatchFinder.first);
        await tester.pump();
        await tester.tap(colorSwatchFinder.first);
        await tester.pump();

        expect(find.text('Selecciona talla y color para ver disponibilidad.'), findsNothing);

        // Fase 11: con una variante concreta elegida, se consulta la
        // disponibilidad por sucursal (mock con ~500ms de latencia).
        await tester.pump(const Duration(milliseconds: 600));

        final branchSectionFinder = find.text('Disponibilidad por sucursal');
        await tester.ensureVisible(branchSectionFinder);
        await tester.pump();

        expect(branchSectionFinder, findsOneWidget);
        expect(find.text('FashionStore San Miguel'), findsOneWidget);
        expect(find.text('La Paz'), findsOneWidget);

        // Fase 13: carrito. La variante S + primer color de "Zapatillas
        // Urbanas" es una combinación disponible (ver
        // CatalogMockDataSource._generateVariants), así que el botón de
        // agregar al carrito debe estar habilitado.
        final addToCartFinder = find.widgetWithText(ElevatedButton, 'Agregar al carrito');
        await tester.ensureVisible(addToCartFinder);
        await tester.pump();
        await tester.tap(addToCartFinder);
        await tester.pump();
        // CartController.addToCart espera dos llamadas secuenciales del
        // mock (agregar el ítem y luego recargar el carrito, ~400ms cada
        // una) antes de mostrar la confirmación.
        await tester.pump(const Duration(milliseconds: 900));

        expect(find.text('Se agregó Zapatillas Urbanas al carrito.'), findsOneWidget);

        // Abre el carrito desde el ícono del AppBar (puede haber más de
        // una instancia montada por el IndexedStack de las pestañas,
        // igual que con el corazón de favoritos en la Fase 12).
        await tester.tap(find.byTooltip('Carrito').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Zapatillas Urbanas'), findsOneWidget);
        expect(find.textContaining('Talla S'), findsOneWidget);

        // Aumentar la cantidad se refleja de inmediato (actualización
        // optimista), sin esperar la respuesta del mock.
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
        expect(find.text('2'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 400));

        // Quitar el ítem deja el carrito vacío.
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Tu carrito está vacío'), findsOneWidget);

        // Fase 14: reservas. Se vuelve al detalle de producto (el carrito
        // se abrió con push, así que sigue debajo en la pila) para
        // agregar la variante ya seleccionada a la reserva (sección 10:
        // varias prendas, sucursal y horario únicos, no una acción de un
        // solo toque por producto).
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final addToReservationFinder = find.widgetWithText(OutlinedButton, 'Agregar a la reserva');
        await tester.ensureVisible(addToReservationFinder);
        await tester.pump();
        await tester.tap(addToReservationFinder);
        await tester.pump();

        expect(find.textContaining('Se agregó Zapatillas Urbanas a tu reserva.'), findsOneWidget);

        // Abre el borrador de reserva desde su ícono en el AppBar.
        await tester.tap(find.byTooltip('Reservar prendas').first);
        await tester.pump();
        // reservationCheckoutControllerProvider carga las sucursales al
        // construirse (~400ms de latencia del mock).
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Zapatillas Urbanas'), findsOneWidget);
        expect(find.textContaining('Talla S'), findsOneWidget);

        // Confirmar sin elegir sucursal ni horario debe mostrar ambos
        // errores de validación en lugar de crear la reserva.
        for (var i = 0; i < 6 && find.text('Confirmar reserva').evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump();
        }
        final confirmReservationFinder = find.widgetWithText(ElevatedButton, 'Confirmar reserva');
        await tester.tap(confirmReservationFinder);
        await tester.pump();

        expect(find.text('Selecciona una sucursal para la reserva.'), findsOneWidget);
        expect(find.text('Elige un horario aproximado.'), findsOneWidget);

        // Elige la sucursal.
        final branchTileFinder = find.text('FashionStore San Miguel');
        await tester.ensureVisible(branchTileFinder);
        await tester.pump();
        await tester.tap(branchTileFinder);
        await tester.pump();

        // Elige el horario: se acepta la fecha y hora por defecto (hoy,
        // ahora) en ambos selectores nativos de Material.
        final scheduleButtonFinder = find.text('Elegir horario');
        await tester.ensureVisible(scheduleButtonFinder);
        await tester.pump();
        await tester.tap(scheduleButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('OK'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('OK'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Selecciona una sucursal para la reserva.'), findsNothing);
        expect(find.text('Elige un horario aproximado.'), findsNothing);

        for (var i = 0; i < 6 && find.text('Confirmar reserva').evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump();
        }
        await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar reserva'));
        await tester.pump();
        // CreateReservationUseCase (~400ms) y la recarga de la lista de
        // reservas (~400ms) antes de mostrar la confirmación.
        await tester.pump(const Duration(milliseconds: 900));

        expect(find.text('Reserva confirmada'), findsOneWidget);
        expect(find.textContaining('FashionStore San Miguel'), findsOneWidget);

        // La reserva se ve reflejada en "Mis reservas".
        await tester.tap(find.widgetWithText(ElevatedButton, 'Ver mis reservas'));
        await tester.pump();

        expect(find.text('Reserva #reservation-1'), findsOneWidget);
        expect(find.textContaining('Zapatillas Urbanas · Talla S'), findsOneWidget);
        expect(find.text('Activa'), findsOneWidget);

        // Cancelar la reserva actualiza su estado sin eliminarla de la
        // lista, para conservar el historial.
        await tester.tap(find.text('Cancelar reserva'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Cancelada'), findsOneWidget);
        expect(find.text('Cancelar reserva'), findsNothing);

        // Fase 15: checkout. Se vuelve al detalle de producto: primero se
        // sale de "Mis reservas" y luego del borrador de reserva, ambos
        // apilados con push sobre la pestaña Catálogo. Tras los dos pop
        // ya se está de vuelta en el detalle (no se vuelve a tocar la
        // pestaña Catálogo: como ya es la pestaña activa, tocarla otra
        // vez reiniciaría esa rama a su raíz, perdiendo el detalle
        // abierto, ver MainScaffold).
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pump();
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final addToCartAgainFinder = find.widgetWithText(ElevatedButton, 'Agregar al carrito');
        await tester.ensureVisible(addToCartAgainFinder);
        await tester.pump();
        await tester.tap(addToCartAgainFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        await tester.tap(find.byTooltip('Carrito').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar a checkout'));
        await tester.pump();
        // checkoutControllerProvider carga las sucursales al construirse
        // (~400ms de latencia del mock).
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Zapatillas Urbanas'), findsOneWidget);
        expect(find.textContaining('Talla S'), findsOneWidget);

        // Cambiar a "Recojo en sucursal" muestra la lista de sucursales
        // en lugar del campo de dirección, y confirmar sin elegir una
        // debe mostrar un error de validación en lugar de crear el pedido.
        await tester.tap(find.text('Recojo en sucursal'));
        await tester.pump();

        expect(find.text('FashionStore San Miguel'), findsOneWidget);
        expect(find.text('Dirección de entrega'), findsNothing);

        // La lista de sucursales empuja el botón fuera del extent
        // construido del ListView (mismo caso que "Descripción" en la
        // Fase 9): hay que desplazarse antes de que exista en el árbol.
        for (var i = 0; i < 6 && find.text('Confirmar pedido').evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump();
        }

        final confirmOrderFinder = find.widgetWithText(ElevatedButton, 'Confirmar pedido');
        await tester.tap(confirmOrderFinder);
        await tester.pump();

        expect(find.text('Selecciona una sucursal para recoger tu pedido.'), findsOneWidget);
        expect(find.text('Pedido creado'), findsNothing);

        // Se vuelve a "Envío a domicilio" (el método que sí se completa
        // en este flujo) y se llena la dirección. El chip quedó arriba
        // del scroll actual, así que hay que traerlo de vuelta a vista.
        final deliveryChipFinder = find.text('Envío a domicilio');
        await tester.ensureVisible(deliveryChipFinder);
        await tester.pump();
        await tester.tap(deliveryChipFinder);
        await tester.pump();

        await tester.enterText(find.byType(TextFormField), 'Av. Siempre Viva 123');
        await tester.pump();

        for (var i = 0; i < 6 && find.text('Confirmar pedido').evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump();
        }
        final confirmDeliveryOrderFinder = find.widgetWithText(ElevatedButton, 'Confirmar pedido');
        await tester.tap(confirmDeliveryOrderFinder);
        await tester.pump();
        // CreateOrderUseCase (~500ms) y CartController.clearCart (~300ms).
        await tester.pump(const Duration(milliseconds: 900));

        expect(find.text('Pedido creado'), findsOneWidget);
        expect(find.textContaining('Av. Siempre Viva 123'), findsOneWidget);

        // Fase 16: pago. En modo mock (AppConfig.useMockData, el valor
        // por defecto de estos tests) no se toca el SDK de Stripe: se
        // muestra el aviso de modo de prueba y un botón de pago directo.
        expect(find.textContaining('Modo de prueba'), findsOneWidget);

        final payButtonFinder = find.widgetWithText(ElevatedButton, 'Pagar Bs 164');
        await tester.ensureVisible(payButtonFinder);
        await tester.pump();
        await tester.tap(payButtonFinder);
        await tester.pump();
        // OrderMockDataSource.payOrder simula ~800ms de procesamiento.
        await tester.pump(const Duration(milliseconds: 800));

        expect(find.text('Pago exitoso'), findsOneWidget);
        expect(find.text('Pedido creado'), findsNothing);

        // El carrito quedó vacío desde que se confirmó el pedido.
        await tester.tap(find.widgetWithText(ElevatedButton, 'Volver al inicio'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1200));

        expect(find.text('Destacados'), findsOneWidget);

        // Fase 17: historial de compras. El pedido recién pagado debe
        // aparecer en "Mis compras", accesible desde el perfil.
        await tester.tap(find.text('Perfil').first);
        await tester.pump();

        final ordersLinkFinder = find.text('Mis compras');
        await tester.ensureVisible(ordersLinkFinder);
        await tester.pump();
        await tester.tap(ordersLinkFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Pedido #order-1'), findsOneWidget);
        expect(find.text('Pagado'), findsOneWidget);
        expect(find.textContaining('Zapatillas Urbanas · Talla S'), findsOneWidget);
        expect(find.textContaining('Av. Siempre Viva 123'), findsOneWidget);

        // Fase 18: asistente IA. Se vuelve al perfil (Mis compras se
        // abrió con push) para entrar al asistente desde su enlace.
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pump();

        final assistantLinkFinder = find.text('Asistente FashionStore');
        await tester.ensureVisible(assistantLinkFinder);
        await tester.pump();
        await tester.tap(assistantLinkFinder);
        await tester.pump();

        // El saludo inicial es local: no requiere esperar ninguna
        // llamada.
        expect(find.textContaining('Hola, soy el asistente de FashionStore'), findsOneWidget);

        // Se envía con la acción "send" del teclado en lugar de tocar el
        // ícono: en el viewport reducido del test, el botón queda tan
        // pegado al borde de la pantalla que el hit test no siempre
        // acierta sobre él.
        await tester.enterText(find.byType(TextField), 'Quiero un vestido');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump();
        // AiAssistantMockDataSource simula ~600ms antes de responder; la
        // respuesta nunca inventa productos, solo usa el catálogo real
        // (sección 15 del documento).
        // El mock espera su propia latencia (~600ms) más las de
        // CatalogDataSource.getCategories() y getProducts() (~500ms
        // cada una) para armar la sugerencia a partir del catálogo real.
        await tester.pump(const Duration(milliseconds: 1700));

        expect(find.textContaining('Vestidos disponibles'), findsOneWidget);
        expect(find.text('Vestido Floral'), findsWidgets);

        // Fase 19: recomendaciones. A esta altura ya se acumularon
        // señales reales: Vestido Floral como favorito (Fase 12, categoría
        // Vestidos) y Zapatillas Urbanas comprado (Fases 15-17, categoría
        // Zapatos). Se invalida el provider para forzar el recálculo con
        // todas esas señales ya presentes (en la app real esto ocurre
        // solo cuando cambian los últimos productos consultados).
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pump();
        await tester.tap(find.text('Home').first);
        await tester.pump();

        // La sección de recomendaciones está más abajo que el extent
        // construido del ListView (mismo caso que "Descripción" en la
        // Fase 9): hay que desplazarse para que ConsumerWidget exista en
        // el árbol. El provider ya se recalculó solo en algún momento
        // desde que existen señales reales (compra y favorito), porque
        // depende de los últimos productos consultados y esos cambiaron
        // varias veces durante el recorrido; no hace falta invalidarlo
        // a mano.
        for (var i = 0; i < 6 && find.text('Recomendado para ti').evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump();
        }

        final recommendationsTitleFinder = find.text('Recomendado para ti');
        expect(recommendationsTitleFinder, findsOneWidget);
        // Botines es una prenda de Zapatos (misma categoría que la
        // compra) que no se compró ni se marcó como favorita, así que
        // debe aparecer como sugerencia real del catálogo.
        expect(find.text('Botines'), findsWidgets);

        // Fase 20: probador virtual por fotografía. Se abre desde el
        // detalle de un producto sugerido; no exige variante elegida ni
        // requiere volver a iniciar sesión (el probador es accesible sin
        // cuenta, ver sección 21).
        final botinesFinder = find.text('Botines').first;
        await tester.ensureVisible(botinesFinder);
        await tester.pump();
        await tester.tap(botinesFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final tryOnEntryFinder = find.widgetWithText(OutlinedButton, 'Probar con tu foto');
        await tester.ensureVisible(tryOnEntryFinder);
        await tester.pump();
        await tester.tap(tryOnEntryFinder);
        await tester.pump();
        // TryOnController.selectProduct se agenda con addPostFrameCallback
        // (no se puede escribir el provider durante build/initState): hace
        // falta un pump extra para que ese callback corra y la pantalla se
        // reconstruya ya con la prenda elegida.
        await tester.pump();

        expect(find.text('Probador virtual'), findsOneWidget);
        expect(find.text('Botines'), findsWidgets);
        // Sin foto todavía, se muestra el ícono de marcador de posición.
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);

        final cameraButtonFinder = find.widgetWithText(OutlinedButton, 'Tomar foto');
        await tester.ensureVisible(cameraButtonFinder);
        await tester.pump();
        await tester.tap(cameraButtonFinder);
        await tester.pump();

        // Con una foto ya elegida, el marcador de posición desaparece y
        // el botón de generar se habilita.
        expect(find.byIcon(Icons.image_outlined), findsNothing);

        final generateButtonFinder = find.widgetWithText(ElevatedButton, 'Generar vista previa');
        await tester.ensureVisible(generateButtonFinder);
        await tester.pump();
        await tester.tap(generateButtonFinder);
        await tester.pump();
        // TryOnMockDataSource simula ~900ms de procesamiento mientras
        // compone la vista previa localmente con dart:ui (no hay backend
        // con Gemini todavía, ver sección 32).
        await tester.pump(const Duration(milliseconds: 900));

        expect(find.textContaining('No se pudo'), findsNothing);
        expect(
          find.textContaining('Esta vista previa se genera en tu dispositivo'),
          findsOneWidget,
        );

        // Fase 21: probador por cámara/AR. Se vuelve al detalle de
        // Botines (donde vive el segundo botón del probador) en lugar de
        // abrir una prenda nueva.
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pump();

        final arEntryFinder = find.widgetWithText(OutlinedButton, 'Probar con cámara (AR)');
        await tester.ensureVisible(arEntryFinder);
        await tester.pump();
        await tester.tap(arEntryFinder);
        await tester.pump();

        expect(find.text('Probador con cámara'), findsOneWidget);

        // ArTryOnController.start() encadena varios await (isAvailable,
        // requestPermission, source.start) antes de suscribirse al
        // stream de poses; varios pumps dejan avanzar cada paso sin
        // depender de un tiempo real fijo.
        await tester.pump();
        await tester.pump();
        await tester.pump();
        // _FakeArCameraSource entrega la pose con un pequeño delay real,
        // después de que el controller ya se suscribió al stream (ver
        // comentario en el fake).
        await tester.pump(const Duration(milliseconds: 50));

        // No se llegó a un estado de error ni de permiso rechazado: se
        // alcanzó el seguimiento en vivo.
        expect(find.textContaining('no tiene una cámara disponible'), findsNothing);
        expect(find.textContaining('necesita permiso de cámara'), findsNothing);
        expect(find.textContaining('No se pudo iniciar la cámara'), findsNothing);

        // El entorno de test no tiene una cámara real que mostrar (el
        // fake no expone un CameraController), así que se ve el mensaje
        // de vista previa no disponible en lugar de CameraPreview.
        expect(find.textContaining('Vista previa de cámara no disponible'), findsOneWidget);

        // Con la pose ya entregada, el aviso de "ubícate frente a la
        // cámara" debe haber desaparecido: hay un cuerpo detectado y la
        // prenda se está superponiendo.
        expect(find.text('Ubícate frente a la cámara, de cuerpo entero.'), findsNothing);

        // La tira para cambiar de prenda (arGarmentOptionsProvider)
        // consulta el catálogo mock, que simula ~500ms de latencia; se
        // espera ese tiempo para no dejar un timer pendiente al terminar
        // el test.
        await tester.pump(const Duration(milliseconds: 600));

        // Fase 22: voz. Se vuelve a Home (dos niveles: el detalle de
        // Botines y luego Home) para reabrir el asistente ya visitado en
        // la Fase 18 y usar el dictado por voz en su composer.
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pump();
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pump();

        final assistantFabFinder = find.widgetWithText(FloatingActionButton, 'Asistente');
        await tester.tap(assistantFabFinder);
        await tester.pump();

        // La conversación de la Fase 18 sigue en memoria
        // (aiAssistantControllerProvider no es autoDispose): se ve el
        // historial previo sin tener que reconstruirlo.
        expect(find.text('Quiero un vestido'), findsOneWidget);

        final micButtonFinder = find.byTooltip('Dictar por voz');
        await tester.tap(micButtonFinder);
        await tester.pump();
        // _FakeVoiceInputSource entrega la transcripción con un pequeño
        // delay real, después de que VoiceInputController ya se
        // suscribió al stream (ver comentario en el fake).
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Quiero un vestido para una fiesta'), findsOneWidget);

        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump();
        // Mismo tiempo de espera que en la Fase 18: el mock simula su
        // propia latencia más la de CatalogDataSource.getCategories() y
        // getProducts().
        await tester.pump(const Duration(milliseconds: 1700));

        expect(find.textContaining('Vestidos disponibles'), findsOneWidget);

        // Escuchar una respuesta del asistente (texto a voz) no debe
        // requerir el plugin real ni romper el flujo.
        final speakerButtonFinder = find.byIcon(Icons.volume_up_outlined).first;
        await tester.ensureVisible(speakerButtonFinder);
        await tester.pump();
        await tester.tap(speakerButtonFinder);
        await tester.pump();

        // Fase 23: almacenamiento local y offline. Se vuelve a Perfil
        // (dentro del shell con bottom nav) para ver el aviso de
        // conectividad, que solo vive en MainScaffold, no en rutas de
        // nivel superior como el asistente.
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pump();

        expect(find.textContaining('Sin conexión a internet'), findsNothing);

        fakeConnectivity.setOnline(false);
        await tester.pump();

        expect(
          find.text('Sin conexión a internet. Mostrando información guardada.'),
          findsOneWidget,
        );

        fakeConnectivity.setOnline(true);
        await tester.pump();

        expect(find.textContaining('Sin conexión a internet'), findsNothing);

        // Los últimos productos consultados ahora se persisten en
        // almacenamiento local (antes de esta fase solo vivían en
        // memoria, ver comentario histórico en RecentlyViewedController):
        // invalidar el provider y volver a leerlo debe restaurar la
        // misma lista guardada, no perderla.
        final recentlyViewedBefore = container.read(recentlyViewedControllerProvider);
        expect(recentlyViewedBefore, isNotEmpty);

        container.invalidate(recentlyViewedControllerProvider);
        await tester.pump();
        await tester.pump();

        expect(container.read(recentlyViewedControllerProvider), recentlyViewedBefore);

        // Invalidar recentlyViewedControllerProvider también recalcula
        // recommendationsProvider (lo observa), que vuelve a combinar
        // productos, favoritos y pedidos; favoritos a su vez consulta el
        // catálogo internamente, encadenando varias latencias simuladas
        // (ver RecommendationMockDataSource y FavoriteMockDataSource).
        // Se espera generosamente para no dejar timers pendientes al
        // terminar el test.
        await tester.pump(const Duration(milliseconds: 2000));
      },
      createHttpClient: (context) => _FakeHttpClient(),
    );
  });
}
