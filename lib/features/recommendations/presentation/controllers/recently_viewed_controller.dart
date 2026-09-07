import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cuántos productos recientes se recuerdan como máximo.
const _maxRecentlyViewed = 10;

/// Últimos productos consultados en este dispositivo (Fase 19, ver
/// sección 16: "historial de navegación" como señal de recomendación,
/// y sección 19: se permite cachear localmente "últimos productos
/// consultados"). Es estado puramente en memoria por ahora; persistirlo
/// entre sesiones es tarea de la Fase 23 (almacenamiento local).
class RecentlyViewedController extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  /// Registra que se consultó [productId], como el más reciente. Si ya
  /// estaba en la lista, se mueve al frente en lugar de duplicarse.
  void recordView(String productId) {
    final withoutCurrent = state.where((id) => id != productId).toList();
    state = [productId, ...withoutCurrent].take(_maxRecentlyViewed).toList();
  }
}

final recentlyViewedControllerProvider = NotifierProvider<RecentlyViewedController, List<String>>(
  RecentlyViewedController.new,
);
