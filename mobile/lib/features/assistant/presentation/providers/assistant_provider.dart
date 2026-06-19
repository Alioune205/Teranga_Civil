import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/upload_document_card.dart'
    show DocumentUploadHelper;
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

  // Identifiant de session de conversation. Le backend l'enregistre comme
  // `session_id` (champ non-nullable) : sans lui, le chat renvoie une 500.
  final String _conversationId =
      'mobile-${DateTime.now().millisecondsSinceEpoch}';

  AssistantNotifier(this._ds) : super(const AssistantState());

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
  }

  void clearHistory() {
    state = state.copyWith(messages: []);
  }

  void addLocalMessage(MessageModel msg) {
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  /// Notation d'une réponse (👍 = 1, 👎 = -1). Optimiste : on met à jour la
  /// bulle immédiatement et on envoie le feedback en arrière-plan (best-effort).
  Future<void> submitFeedback(String messageId, int rating) async {
    final idx = state.messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    final msg = state.messages[idx];
    if (msg.logId == null || msg.feedbackRating != 0) return; // déjà noté

    final updated = [...state.messages];
    updated[idx] = msg.copyWith(feedbackRating: rating);
    state = state.copyWith(messages: updated);

    try {
      await _ds.sendFeedback(logId: msg.logId!, rating: rating);
    } catch (_) {
      // Silencieux : la note reste affichée, l'échec n'interrompt pas l'UI.
    }
  }

  Future<void> sendMessage(String content, {String? imagePath}) async {
    final hasImage = imagePath != null;
    if (content.trim().isEmpty && !hasImage) return;

    // Encodage de l'image (vision Ndiogoye) si une pièce est jointe.
    String? imageBase64;
    if (hasImage) {
      final bytes = DocumentUploadHelper.bytesFor(imagePath);
      if (bytes != null) imageBase64 = base64Encode(bytes);
    }

    // Texte affiché dans la bulle utilisateur (et message réellement envoyé).
    final display = content.trim().isNotEmpty
        ? content
        : (hasImage ? '📷 Document envoyé' : content);
    final sent = content.trim().isNotEmpty
        ? content
        : (hasImage ? 'Peux-tu analyser ce document ?' : content);

    final userMsg = MessageModel.user(display, language: state.language);
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
        message: sent,
        language: state.language,
        history: history,
        conversationId: _conversationId,
        imageBase64: imageBase64,
      );

      final assistantMsg = MessageModel.assistant(
        response.reply,
        language: state.language,
        logId: response.logId,
        action: response.action,
        dossierReference: response.dossierReference,
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
