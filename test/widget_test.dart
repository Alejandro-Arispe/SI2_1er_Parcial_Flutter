import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_store/app/app.dart';
import 'package:fashion_store/core/security/secure_storage_service.dart';

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

void main() {
  testWidgets('La app arranca en splash y redirige a Home sin sesión', (WidgetTester tester) async {
    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [secureStorageServiceProvider.overrideWithValue(_FakeSecureStorageService())],
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

        // Navega a la pestaña Catálogo (Fase 7) y espera su carga inicial
        // (categorías + primera página de productos, cada una con la
        // misma latencia simulada que Home).
        await tester.tap(find.text('Catálogo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1200));

        expect(find.text('Todas'), findsOneWidget);
        expect(find.text('Vestido Floral'), findsWidgets);
      },
      createHttpClient: (context) => _FakeHttpClient(),
    );
  });
}
