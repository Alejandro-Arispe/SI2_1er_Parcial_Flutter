import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/storage/local_storage_service.dart';

/// Cuántos productos recientes se recuerdan como máximo.
const _maxRecentlyViewed = 10;

const _storageKey = 'recently_viewed_product_ids';

/// Últimos productos consultados en este dispositivo (Fase 19, ver
/// sección 16: "historial de navegación" como señal de recomendación).
/// Se persiste en almacenamiento local (Fase 23, sección 19: "últimos
/// productos consultados" es justo uno de los datos no críticos que la
/// sección menciona como candidato) para que la lista sobreviva a cerrar
/// la app, en lugar de perderse en cada reinicio.
class RecentlyViewedController extends Notifier<List<String>> {
  @override
  List<String> build() {
    _restore(); // no debe tocar state antes del primer await (ver FavoritesController)
    return const [];
  }

  Future<void> _restore() async {
    final raw = await ref.read(localStorageServiceProvider).readString(_storageKey);
    if (raw == null) return;
    try {
      final ids = (jsonDecode(raw) as List).cast<String>();
      state = ids.take(_maxRecentlyViewed).toList();
    } catch (_) {
      // Dato local corrupto o de un formato anterior: se ignora y se
      // sigue con la lista vacía en lugar de romper la pantalla.
    }
  }

  /// Registra que se consultó [productId], como el más reciente. Si ya
  /// estaba en la lista, se mueve al frente en lugar de duplicarse.
  void recordView(String productId) {
    final withoutCurrent = state.where((id) => id != productId).toList();
    state = [productId, ...withoutCurrent].take(_maxRecentlyViewed).toList();
    unawaited(ref.read(localStorageServiceProvider).writeString(_storageKey, jsonEncode(state)));
  }
}

final recentlyViewedControllerProvider = NotifierProvider<RecentlyViewedController, List<String>>(
  RecentlyViewedController.new,
);
