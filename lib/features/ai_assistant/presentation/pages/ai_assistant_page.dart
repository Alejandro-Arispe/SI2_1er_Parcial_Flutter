import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/voice/flutter_tts_voice_output_source.dart';
import 'package:fashion_store/features/ai_assistant/domain/entities/assistant_message.dart';
import 'package:fashion_store/features/ai_assistant/presentation/controllers/ai_assistant_controller.dart';
import 'package:fashion_store/features/ai_assistant/presentation/controllers/voice_input_controller.dart';
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

    // El dictado por voz (Fase 22) llena el campo de texto a medida que
    // se reconocen palabras, en lugar de que el composer tenga que leer
    // el provider directamente: así el TextEditingController (que es de
    // este State, no de Riverpod) se mantiene como la única fuente de
    // verdad del texto que se va a enviar.
    ref.listen(voiceInputControllerProvider, (previous, next) {
      if (next.transcript != (previous?.transcript ?? '')) {
        _textController.value = TextEditingValue(
          text: next.transcript,
          selection: TextSelection.collapsed(offset: next.transcript.length),
        );
      }
      if (next.status == VoiceInputStatus.unavailable &&
          previous?.status != VoiceInputStatus.unavailable) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('No se pudo acceder al micrófono en este dispositivo.'),
            ),
          );
      }
    });

    final voiceState = ref.watch(voiceInputControllerProvider);

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
          _Composer(
            controller: _textController,
            enabled: !state.isSending,
            isListening: voiceState.status == VoiceInputStatus.listening,
            onSend: _send,
            onToggleVoice: () => ref.read(voiceInputControllerProvider.notifier).toggleListening(),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final AssistantMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Leer en voz alta (Fase 22, sección 18) solo tiene sentido
          // para las respuestas del asistente: el mensaje de la propia
          // clienta ya lo dijo ella, no hace falta que la app lo repita.
          if (!isUser)
            IconButton(
              tooltip: 'Escuchar respuesta',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.volume_up_outlined),
              onPressed: () => ref.read(voiceOutputSourceProvider).speak(message.content),
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
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onToggleVoice;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.isListening,
    required this.onSend,
    required this.onToggleVoice,
  });

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
              // Dictado por voz (Fase 22, sección 18 del documento):
              // alternativa a escribir, no reemplaza el campo de texto,
              // así la clienta puede corregir lo reconocido antes de
              // enviar.
              IconButton(
                tooltip: isListening ? 'Detener dictado' : 'Dictar por voz',
                icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                color: isListening ? AppColors.primary : null,
                onPressed: enabled ? onToggleVoice : null,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: isListening ? 'Escuchando...' : 'Escribe tu consulta...',
                    border: const OutlineInputBorder(),
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
