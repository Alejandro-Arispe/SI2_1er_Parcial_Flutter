import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_store/app/app.dart';
import 'package:fashion_store/core/security/secure_storage_service.dart';
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
        // descripción quede dentro del árbol de widgets construido.
        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pump();

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
      },
      createHttpClient: (context) => _FakeHttpClient(),
    );
  });
}
