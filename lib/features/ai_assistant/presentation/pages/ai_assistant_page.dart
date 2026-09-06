import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';
import 'package:fashion_store/features/ai_assistant/presentation/controllers/ai_assistant_controller.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/presentation/widgets/product_card.dart';

/// Asistente inteligente (Fase 18, ver sección 15 del documento):
/// conversación con IA sobre el catálogo (combinaciones, recomendaciones,
/// disponibilidad). Requiere sesión iniciada (protegido por el router).
/// La integración con Gemini vive en el backend (Flutter -> FastAPI ->
/// Gemini, ver sección 14); esta pantalla solo conversa con esa API.
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await ref.read(aiAssistantControllerProvider.notifier).sendMessage(text);
    if (!mounted) return;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Asistente FashionStore')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.messages.length + (state.isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: state.messages[index]);
              },
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                state.error!.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ),
          _Composer(controller: _textController, enabled: !state.isSending, onSend: _send),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AssistantMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.skeleton,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isUser ? AppColors.textOnPrimary : AppColors.textPrimary,
                  ),
            ),
          ),
          if (message.suggestedProducts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _SuggestedProducts(products: message.suggestedProducts),
          ],
        ],
      ),
    );
  }
}

/// Prendas reales del catálogo que acompañan la respuesta del asistente
/// (sección 15: nunca se inventan productos). Reutiliza ProductCard.
/// Navega con go() y no push(): el detalle de producto vive anidado
/// dentro del shell de navegación (pestaña Catálogo) y el asistente es
/// una ruta de nivel superior fuera de él; empujar esa ruta anidada
/// desde aquí duplica la clave global del shell que ya existe debajo en
/// la pila y GoRouter lo rechaza ("!keyReservation.contains(key)").
class _SuggestedProducts extends StatelessWidget {
  final List<Product> products;

  const _SuggestedProducts({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            width: 130,
            onTap: () => context.go(RoutePaths.productDetail(product.id)),
          );
        },
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.skeleton,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _Composer({required this.controller, required this.enabled, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu consulta...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Enviar',
                icon: const Icon(Icons.send),
                onPressed: enabled ? onSend : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
