import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';

/// Réponse structurée de Ndiogoye.
/// Le backend renvoie un JSON synchrone (PAS de SSE malgré le guide) :
///   {reply, intent, action, log_id?, dossier_reference?}
/// `action` ∈ RESPOND / CLARIFY / SHOW_PAYMENT_AND_DOSSIER / FALLBACK.
class NdiogoyeReply {
  final String reply;
  final String action;
  final String? logId;
  final String? dossierReference;

  const NdiogoyeReply({
    required this.reply,
    this.action = 'RESPOND',
    this.logId,
    this.dossierReference,
  });
}

class AssistantRemoteDatasource {
  final DioClient client;
  const AssistantRemoteDatasource({required this.client});

  Future<NdiogoyeReply> sendMessage({
    required String message,
    required String language,
    List<Map<String, dynamic>>? history,
    String? conversationId,
    String? imageBase64,
  }) async {
    // Backend (NdiogoyeChatView) : POST /api/ai/ndiogoye/chat/
    //   body  {message, chat_history:[{role, content}], conversation_id,
    //          image_base64?}
    //   -> {reply, intent, action, log_id?, dossier_reference?}
    // `conversation_id` est requis en pratique : le backend l'enregistre en
    // `session_id` non-nullable et renvoie une 500 s'il est absent.
    // `image_base64` (optionnel) : Ndiogoye lit le document photographié (vision).
    final res = await client.post('/ai/ndiogoye/chat/', data: {
      'message': message,
      'chat_history': history ?? [],
      if (conversationId != null) 'conversation_id': conversationId,
      if (imageBase64 != null) 'image_base64': imageBase64,
    });
    if ((res.statusCode == 200) && res.data is Map<String, dynamic>) {
      final data = res.data as Map<String, dynamic>;
      // `reply` est le champ officiel ; `answer` gardé en repli défensif.
      final reply = (data['reply'] ?? data['answer']) as String?;
      if (reply != null && reply.isNotEmpty) {
        return NdiogoyeReply(
          reply: reply,
          action: (data['action'] as String?) ?? 'RESPOND',
          logId: data['log_id']?.toString(),
          dossierReference: data['dossier_reference'] as String?,
        );
      }
    }
    throw const ApiException(message: 'Réponse invalide du serveur');
  }

  /// Notation d'une réponse : POST /api/ai/ndiogoye/feedback/
  ///   body {log_id, rating: 1|-1, comment?} -> {status:"success"}
  /// Best-effort : on n'interrompt jamais l'UI si le feedback échoue.
  Future<void> sendFeedback({
    required String logId,
    required int rating,
    String? comment,
  }) async {
    await client.post('/ai/ndiogoye/feedback/', data: {
      'log_id': logId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }
}
