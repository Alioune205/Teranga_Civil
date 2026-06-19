#!/bin/bash
# ============================================================
# TERANGA CIVIL — Étape 8 : ASSISTANT + PROFIL + FINALISATION
# Usage : bash setup_etape8.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Installation Étape 8 : ASSISTANT + PROFIL + FINALISATION"
echo ""

mkdir -p test/features/auth
mkdir -p test/features/profile

# ════════════════════════════════════════════════════════════
# FEATURE ASSISTANT
# ════════════════════════════════════════════════════════════

cat > lib/features/assistant/domain/models/message_model.dart << 'DART'
/// Modèle d'un message dans la conversation avec l'assistant IA
class MessageModel {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String language; // 'fr' ou 'wo'

  const MessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.language = 'fr',
  });

  factory MessageModel.user(String content, {String language = 'fr'}) =>
      MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
        language: language,
      );

  factory MessageModel.assistant(String content, {String language = 'fr'}) =>
      MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
        language: language,
      );
}
DART
echo "  ✅ message_model.dart"

cat > lib/features/assistant/data/remote_datasource.dart << 'DART'
import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';

class AssistantRemoteDatasource {
  final DioClient client;
  const AssistantRemoteDatasource({required this.client});

  Future<String> sendMessage({
    required String message,
    required String language,
    List<Map<String, dynamic>>? history,
  }) async {
    final res = await client.post('/assistant/chat', data: {
      'message': message,
      'language': language,
      'history': history ?? [],
    });
    if ((res.statusCode == 200) && res.data != null) {
      return (res.data as Map<String, dynamic>)['response'] as String;
    }
    throw const ApiException(message: 'Réponse invalide du serveur');
  }
}
DART
echo "  ✅ assistant remote_datasource.dart"

cat > lib/features/assistant/presentation/providers/assistant_provider.dart << 'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/remote_datasource.dart';
import '../../domain/models/message_model.dart';

class AssistantState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;
  final String language;

  const AssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.language = 'fr',
  });

  AssistantState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    String? language,
    bool clearError = false,
  }) =>
      AssistantState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        language: language ?? this.language,
      );
}

class AssistantNotifier extends StateNotifier<AssistantState> {
  final AssistantRemoteDatasource _ds;

  AssistantNotifier(this._ds) : super(const AssistantState());

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
  }

  void clearHistory() {
    state = state.copyWith(messages: []);
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Ajouter le message utilisateur immédiatement
    final userMsg = MessageModel.user(content, language: state.language);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      clearError: true,
    );

    try {
      final history = state.messages
          .take(state.messages.length - 1) // exclure le dernier (vient d'être ajouté)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final response = await _ds.sendMessage(
        message: content,
        language: state.language,
        history: history,
      );

      final assistantMsg = MessageModel.assistant(
        response,
        language: state.language,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
    } catch (e) {
      // Message d'erreur dans la conversation
      final errMsg = MessageModel.assistant(
        state.language == 'fr'
            ? 'Désolé, je ne suis pas disponible pour le moment. Réessayez dans quelques instants.'
            : 'Baal ma, maa ngi ci kanam. Jéfandiku ko ëllëk bi.',
        language: state.language,
      );
      state = state.copyWith(
        messages: [...state.messages, errMsg],
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final assistantProvider =
    StateNotifierProvider<AssistantNotifier, AssistantState>((ref) =>
        AssistantNotifier(
          AssistantRemoteDatasource(client: ref.read(dioClientProvider)),
        ));
DART
echo "  ✅ assistant_provider.dart"

cat > lib/features/assistant/presentation/screens/assistant_sheet.dart << 'DART'
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
DART
echo "  ✅ assistant_sheet.dart"

# ════════════════════════════════════════════════════════════
# FEATURE PROFILE
# ════════════════════════════════════════════════════════════

cat > lib/features/profile/data/models/profile_model.dart << 'DART'
class ProfileUpdateModel {
  final String? nom;
  final String? communeId;

  const ProfileUpdateModel({this.nom, this.communeId});

  Map<String, dynamic> toJson() => {
        if (nom != null) 'nom': nom,
        if (communeId != null) 'commune_id': communeId,
      };
}
DART
echo "  ✅ profile_model.dart"

cat > lib/features/profile/data/remote_datasource.dart << 'DART'
import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import '../../auth/data/models/auth_response_model.dart';

class ProfileRemoteDatasource {
  final DioClient client;
  const ProfileRemoteDatasource({required this.client});

  Future<UserResponseModel> getProfile() async {
    final res = await client.get('/auth/me');
    if (res.statusCode == 200 && res.data != null) {
      return UserResponseModel.fromJson(res.data as Map<String, dynamic>);
    }
    throw const UnauthorizedException();
  }

  Future<UserResponseModel> updateProfile(Map<String, dynamic> data) async {
    final res = await client.put('/profile/update', data: data);
    if (res.statusCode == 200 && res.data != null) {
      return UserResponseModel.fromJson(res.data as Map<String, dynamic>);
    }
    throw ApiException(
        message: 'Mise à jour échouée', statusCode: res.statusCode);
  }

  Future<void> changePin({
    required String oldPinHash,
    required String newPin,
  }) async {
    final res = await client.put('/profile/change-pin', data: {
      'old_pin_hash': oldPinHash,
      'new_pin': newPin,
    });
    if (res.statusCode != 200) {
      throw ApiException(
          message: 'Changement de PIN échoué', statusCode: res.statusCode);
    }
  }
}
DART
echo "  ✅ profile remote_datasource.dart"

cat > lib/features/profile/presentation/providers/profile_provider.dart << 'DART'
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/remote_datasource.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final bool updateSuccess;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.updateSuccess = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    bool? updateSuccess,
    bool clearError = false,
  }) =>
      ProfileState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        updateSuccess: updateSuccess ?? this.updateSuccess,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRemoteDatasource _ds;
  final Ref _ref;

  ProfileNotifier(this._ds, this._ref) : super(const ProfileState());

  Future<UserModel?> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _ds.getProfile();
      final user = res.toDomain();
      state = state.copyWith(isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> updateProfile({String? nom, String? communeId}) async {
    state = state.copyWith(isLoading: true, clearError: true, updateSuccess: false);
    try {
      final data = <String, dynamic>{
        if (nom != null) 'nom': nom,
        if (communeId != null) 'commune_id': communeId,
      };
      await _ds.updateProfile(data);
      state = state.copyWith(isLoading: false, updateSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final oldHash = sha256.convert(utf8.encode(oldPin)).toString();
      await _ds.changePin(oldPinHash: oldHash, newPin: newPin);
      state = state.copyWith(isLoading: false, updateSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _ref.read(authProvider.notifier).logout();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) =>
        ProfileNotifier(
          ProfileRemoteDatasource(client: ref.read(dioClientProvider)),
          ref,
        ));
DART
echo "  ✅ profile_provider.dart"

cat > lib/features/profile/presentation/screens/profile_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// S14 — Profil utilisateur
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final initials = user != null
        ? AppFormatters.initials(user.nom)
        : '?';
    final nom = user?.nom ?? '—';
    final phone = user != null
        ? AppFormatters.phoneNumber(user.phone)
        : '—';
    final commune = user?.communeNom ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ── Avatar + infos ──────────────────────────────
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(nom, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 4),
                  Text(phone, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusGreenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      commune,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Sections ────────────────────────────────────
              _SectionCard(
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline,
                    label: 'Mes informations',
                    onTap: () => _showEditProfile(context, ref, nom),
                  ),
                  _ProfileTile(
                    icon: Icons.lock_outline,
                    label: 'Changer le code PIN',
                    onTap: () => _showChangePIN(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  _ProfileTile(
                    icon: Icons.language_outlined,
                    label: 'Langue',
                    trailing: Text('Français',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary)),
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.secondary,
                    ),
                    onTap: null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  _ProfileTile(
                    icon: Icons.help_outline,
                    label: 'Aide & Support',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.info_outline,
                    label: 'À propos',
                    trailing: Text(
                      'v${AppConstants.appVersion}',
                      style: AppTextStyles.caption,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Déconnexion ─────────────────────────────────
              _SectionCard(
                children: [
                  _ProfileTile(
                    icon: Icons.logout,
                    label: 'Déconnexion',
                    labelColor: AppColors.error,
                    iconColor: AppColors.error,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, String currentNom) {
    final ctrl = TextEditingController(text: currentNom);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier mon profil', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Nom complet',
              controller: ctrl,
              validator: Validators.fullName,
            ),
            const SizedBox(height: 20),
            Consumer(builder: (_, ref, __) {
              final isLoading = ref.watch(profileProvider).isLoading;
              return PrimaryButton(
                label: 'Enregistrer',
                isLoading: isLoading,
                onPressed: () async {
                  if (Validators.fullName(ctrl.text) != null) return;
                  await ref
                      .read(profileProvider.notifier)
                      .updateProfile(nom: ctrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showChangePIN(BuildContext context, WidgetRef ref) {
    final oldCtr = TextEditingController();
    final newCtr = TextEditingController();
    final confirmCtr = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Changer le code PIN', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Code PIN actuel',
              controller: oldCtr,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Nouveau code PIN',
              controller: newCtr,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: Validators.pin,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Confirmer le nouveau PIN',
              controller: confirmCtr,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 20),
            Consumer(builder: (_, ref, __) {
              final isLoading = ref.watch(profileProvider).isLoading;
              return PrimaryButton(
                label: 'Confirmer',
                isLoading: isLoading,
                onPressed: () async {
                  if (newCtr.text != confirmCtr.text) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Les codes PIN ne correspondent pas.')));
                    return;
                  }
                  if (Validators.pin(newCtr.text) != null) return;
                  try {
                    await ref.read(profileProvider.notifier).changePin(
                          oldPin: oldCtr.text,
                          newPin: newCtr.text,
                        );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Code PIN modifié avec succès.')));
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error));
                    }
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Déconnexion', style: AppTextStyles.headlineSmall),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: AppTextStyles.linkPrimary),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(profileProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: Text('Déconnexion',
                style: AppTextStyles.link.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast) const Divider(height: 1, indent: 52),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _ProfileTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: iconColor ?? AppColors.textSecondary, size: 22),
      title: Text(label,
          style: AppTextStyles.bodyMedium.copyWith(color: labelColor)),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textHint)
              : null),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
DART
echo "  ✅ profile_screen.dart"

# ════════════════════════════════════════════════════════════
# MISE À JOUR main_scaffold — brancher AssistantSheet
# ════════════════════════════════════════════════════════════

cat > lib/shared/layout/main_scaffold.dart << 'DART'
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/assistant/presentation/screens/assistant_sheet.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  static const _tabs = [
    _NavTab(label: 'Accueil',  icon: Icons.home_outlined,   activeIcon: Icons.home,   route: '/home'),
    _NavTab(label: 'Dossiers', icon: Icons.folder_outlined, activeIcon: Icons.folder, route: '/dossiers'),
    _NavTab(label: 'Profil',   icon: Icons.person_outlined, activeIcon: Icons.person, route: '/profile'),
  ];

  void _onTabTapped(BuildContext context, int index) {
    if (index == currentIndex) return;
    context.go(_tabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => AssistantSheet.show(context),
        backgroundColor: AppColors.secondary,
        elevation: 4,
        tooltip: 'Assistant IA',
        child: const Icon(Icons.mic, color: AppColors.textOnPrimary, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _TerangaBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => _onTabTapped(context, i),
      ),
    );
  }
}

class _TerangaBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _TerangaBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      elevation: 8,
      notchMargin: 8,
      shape: const CircularNotchThapShape(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(tab: MainScaffold._tabs[0], isActive: currentIndex == 0, onTap: () => onTap(0)),
            _NavItem(tab: MainScaffold._tabs[1], isActive: currentIndex == 1, onTap: () => onTap(1)),
            const SizedBox(width: 64),
            _NavItem(tab: MainScaffold._tabs[2], isActive: currentIndex == 2, onTap: () => onTap(2)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.tab, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? tab.activeIcon : tab.icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(tab.label, style: AppTextStyles.navLabel.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavTab({required this.label, required this.icon, required this.activeIcon, required this.route});
}

class CircularNotchThapShape extends NotchedShape {
  const CircularNotchThapShape();

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) return Path()..addRect(host);
    const r = 32.0;
    final a = -1.0 * r - 8;
    final b = host.top - guest.center.dy;
    final n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final p2yA = math.sqrt(r * r - p2xA * p2xA);
    final p2yB = math.sqrt(r * r - p2xB * p2xB);
    final p = [
      Offset(guest.center.dx + p2xA, host.top - p2yA),
      Offset(guest.center.dx + p2xB, host.top - p2yB),
    ];
    final lp = p[0].dx < p[1].dx ? p[0] : p[1];
    final rp = p[0].dx < p[1].dx ? p[1] : p[0];
    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(lp.dx - r, host.top)
      ..quadraticBezierTo(lp.dx, host.top, lp.dx, lp.dy)
      ..arcToPoint(rp, radius: Radius.circular(r), clockwise: false)
      ..quadraticBezierTo(rp.dx, host.top, rp.dx + r, host.top)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();
  }
}
DART
echo "  ✅ main_scaffold.dart (mis à jour avec AssistantSheet)"

# ════════════════════════════════════════════════════════════
# TESTS FINAUX
# ════════════════════════════════════════════════════════════

cat > test/features/auth/registration_data_test.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('RegistrationData', () {
    test('isStep1Valid est false si champs manquants', () {
      const data = RegistrationData();
      expect(data.isStep1Valid, isFalse);
    });

    test('isStep1Valid est true si tous les champs sont remplis', () {
      final data = RegistrationData(
        nom: 'Amadou Diallo',
        registre: 'SN-123456-A',
        dateNaissance: DateTime(1990, 5, 15),
        phone: '771234567',
      );
      expect(data.isStep1Valid, isTrue);
    });

    test('isStep2Valid est false si commune non sélectionnée', () {
      const data = RegistrationData();
      expect(data.isStep2Valid, isFalse);
    });

    test('isStep2Valid est true si communeId renseigné', () {
      const data = RegistrationData(communeId: 'DK-DK-01');
      expect(data.isStep2Valid, isTrue);
    });

    test('copyWith préserve les valeurs non modifiées', () {
      const data = RegistrationData(nom: 'Amadou', phone: '771234567');
      final updated = data.copyWith(nom: 'Fatou');
      expect(updated.nom, equals('Fatou'));
      expect(updated.phone, equals('771234567'));
    });

    test('toMap retourne les bonnes clés', () {
      const data = RegistrationData(
        nom: 'Amadou', registre: 'SN-1', phone: '77',
        communeId: 'c1', communeNom: 'Dakar',
      );
      final map = data.toMap();
      expect(map.containsKey('nom'), isTrue);
      expect(map.containsKey('phone'), isTrue);
      expect(map.containsKey('communeId'), isTrue);
    });
  });
}
DART
echo "  ✅ registration_data_test.dart"

cat > test/features/profile/profile_model_test.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/profile/data/models/profile_model.dart';

void main() {
  group('ProfileUpdateModel', () {
    test('toJson inclut uniquement les champs non nuls', () {
      const model = ProfileUpdateModel(nom: 'Amadou');
      final json = model.toJson();
      expect(json.containsKey('nom'), isTrue);
      expect(json.containsKey('commune_id'), isFalse);
    });

    test('toJson inclut les deux champs si fournis', () {
      const model = ProfileUpdateModel(nom: 'Amadou', communeId: 'DK-01');
      final json = model.toJson();
      expect(json['nom'], equals('Amadou'));
      expect(json['commune_id'], equals('DK-01'));
    });

    test('toJson retourne un map vide si aucun champ fourni', () {
      const model = ProfileUpdateModel();
      expect(model.toJson().isEmpty, isTrue);
    });
  });
}
DART
echo "  ✅ profile_model_test.dart"

cat > test/features/auth/auth_state_test.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('AuthState.copyWith', () {
    test('copyWith avec clearError efface le message d erreur', () {
      const state = AuthState(error: 'Erreur test');
      final updated = state.copyWith(clearError: true);
      expect(updated.error, isNull);
    });

    test('copyWith préserve les valeurs non modifiées', () {
      const state = AuthState(isLoading: true, isAuthenticated: false);
      final updated = state.copyWith(isAuthenticated: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isAuthenticated, isTrue);
    });

    test('état initial est cohérent', () {
      const state = AuthState();
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, isNull);
      expect(state.user, isNull);
    });
  });
}
DART
echo "  ✅ auth_state_test.dart"

echo ""
echo "✅ Étape 8 terminée — projet TERANGA CIVIL COMPLET !"
echo ""
echo "Fichiers générés :"
echo "  lib/features/assistant/domain/models/message_model.dart"
echo "  lib/features/assistant/data/remote_datasource.dart"
echo "  lib/features/assistant/presentation/providers/assistant_provider.dart"
echo "  lib/features/assistant/presentation/screens/assistant_sheet.dart"
echo "  lib/features/profile/data/models/profile_model.dart"
echo "  lib/features/profile/data/remote_datasource.dart"
echo "  lib/features/profile/presentation/providers/profile_provider.dart"
echo "  lib/features/profile/presentation/screens/profile_screen.dart"
echo "  lib/shared/layout/main_scaffold.dart (mis à jour)"
echo "  test/features/auth/registration_data_test.dart"
echo "  test/features/auth/auth_state_test.dart"
echo "  test/features/profile/profile_model_test.dart"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Lancer tous les tests :"
echo "  flutter test"
echo ""
echo "  Lancer l'app :"
echo "  flutter run"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
