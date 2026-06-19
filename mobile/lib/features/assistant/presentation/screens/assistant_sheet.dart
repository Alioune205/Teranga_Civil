import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/assistant_provider.dart';
import '../../domain/models/message_model.dart';

/// S13 — Bottom sheet assistant IA vocal (Français / Wolof)
class AssistantSheet extends ConsumerStatefulWidget {
  const AssistantSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AssistantSheet(),
    );
  }

  @override
  ConsumerState<AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends ConsumerState<AssistantSheet> {
  final _textCtr = TextEditingController();
  final _scrollCtr = ScrollController();
  bool _isListening = false;

  static const _suggestions = {
    'fr': [
      'Comment demander un certificat de naissance ?',
      'Quel est le délai pour un certificat de mariage ?',
      'Comment suivre mon dossier ?',
      'Quels sont les frais de service ?',
    ],
    'wo': [
      'Ana wàllu bi pour certificat bu jigéen ?',
      'Ndax xam naa li ngay def ci certificat bu naissance ?',
      'Lan la certificat bu mariage wara fa ?',
    ],
  };

  @override
  void dispose() {
    _textCtr.dispose();
    _scrollCtr.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtr.hasClients) {
        _scrollCtr.animateTo(
          _scrollCtr.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _textCtr.clear();
    await ref.read(assistantProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);
    final suggestions = _suggestions[state.language] ?? _suggestions['fr']!;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle ──────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_outlined,
                        color: AppColors.textOnPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assistant TERANGA CIVIL',
                            style: AppTextStyles.labelLarge),
                        Text(
                          state.language == 'fr'
                              ? 'Je vous aide en Français'
                              : 'Maa ngi ci kanam ci Wolof',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  // Sélecteur de langue
                  _LangToggle(
                    current: state.language,
                    onChanged: (lang) =>
                        ref.read(assistantProvider.notifier).setLanguage(lang),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Zone conversation ────────────────────────────
            Expanded(
              child: state.messages.isEmpty
                  ? _SuggestionsView(
                      suggestions: suggestions,
                      onTap: _send,
                      language: state.language,
                    )
                  : ListView.builder(
                      controller: _scrollCtr,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length +
                          (state.isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == state.messages.length && state.isLoading) {
                          return const _TypingIndicator();
                        }
                        return _MessageBubble(msg: state.messages[i]);
                      },
                    ),
            ),

            // ── Zone saisie ──────────────────────────────────
            _InputBar(
              controller: _textCtr,
              isLoading: state.isLoading,
              isListening: _isListening,
              language: state.language,
              onSend: _send,
              onMic: () => setState(() => _isListening = !_isListening),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sélecteur langue ──────────────────────────────────────────────────────────
class _LangToggle extends StatelessWidget {
  final String current;
  final void Function(String) onChanged;
  const _LangToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangBtn(label: '🇫🇷 FR', selected: current == 'fr',
              onTap: () => onChanged('fr')),
          _LangBtn(label: 'WO', selected: current == 'wo',
              onTap: () => onChanged('wo')),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

// ── Suggestions ───────────────────────────────────────────────────────────────
class _SuggestionsView extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  final String language;
  const _SuggestionsView({
    required this.suggestions,
    required this.onTap,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.statusGreenLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic,
                      color: AppColors.secondary, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  language == 'fr'
                      ? 'Comment puis-je vous aider ?'
                      : 'Lan lën maa def ngir yëngël ci kanam ?',
                  style: AppTextStyles.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  language == 'fr'
                      ? 'Posez votre question ou choisissez un exemple'
                      : 'Laaj sa laaj wala tann ci ci kaw',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            language == 'fr' ? 'Questions fréquentes' : 'Laajal yu bëgg',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 12),
          ...suggestions.map((s) => GestureDetector(
                onTap: () => onTap(s),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s, style: AppTextStyles.bodyMedium),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppColors.textHint),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Bulle de message ──────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: AppColors.textOnPrimary, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isUser
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.timeAgo(msg.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: isUser
                          ? AppColors.textOnPrimary.withValues(alpha: 0.6)
                          : AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Indicateur frappe ─────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
                color: AppColors.secondary, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_outlined,
                color: AppColors.textOnPrimary, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: List.generate(3, (i) => AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withValues(
                          alpha: (i == 0
                              ? _ctrl.value
                              : i == 1
                                  ? (_ctrl.value + 0.3).clamp(0, 1)
                                  : (_ctrl.value + 0.6).clamp(0, 1))
                              .toDouble(),
                        ),
                      ),
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barre de saisie ───────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isListening;
  final String language;
  final void Function(String) onSend;
  final VoidCallback onMic;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.isListening,
    required this.language,
    required this.onSend,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Bouton micro
          GestureDetector(
            onTap: onMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isListening
                    ? AppColors.secondary
                    : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isListening ? AppColors.secondary : AppColors.border,
                ),
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none_outlined,
                color: isListening
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Champ texte
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.inputText,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              decoration: InputDecoration(
                hintText: language == 'fr'
                    ? 'Posez votre question...'
                    : 'Laaj sa laaj...',
                hintStyle: AppTextStyles.inputHint,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Bouton envoyer
          GestureDetector(
            onTap: isLoading ? null : () => onSend(controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isLoading ? AppColors.border : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: AppColors.textOnPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
