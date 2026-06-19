enum MessageType { text, voice, image, file }

/// Modèle d'un message dans la conversation avec l'agent IA
class MessageModel {
  final String id;
  final String content;       // texte ou transcription vocale
  final bool isUser;
  final DateTime timestamp;
  final String language;      // 'fr' ou 'wo'
  final MessageType type;
  final String? filePath;     // chemin local pour voix/image/fichier
  final String? fileName;     // nom affiché pour les fichiers
  final int? durationSec;     // durée en secondes pour les vocaux

  // ── Champs spécifiques aux réponses de Ndiogoye ──────────────────────
  final String? logId;            // id pour noter la réponse (feedback)
  final String action;            // RESPOND / SHOW_PAYMENT_AND_DOSSIER / ...
  final String? dossierReference; // ref. du dossier créé (ex: DOS-1234)
  final int feedbackRating;       // 0 = non noté, 1 = 👍, -1 = 👎

  const MessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.language = 'fr',
    this.type = MessageType.text,
    this.filePath,
    this.fileName,
    this.durationSec,
    this.logId,
    this.action = 'RESPOND',
    this.dossierReference,
    this.feedbackRating = 0,
  });

  MessageModel copyWith({int? feedbackRating}) => MessageModel(
        id: id,
        content: content,
        isUser: isUser,
        timestamp: timestamp,
        language: language,
        type: type,
        filePath: filePath,
        fileName: fileName,
        durationSec: durationSec,
        logId: logId,
        action: action,
        dossierReference: dossierReference,
        feedbackRating: feedbackRating ?? this.feedbackRating,
      );

  factory MessageModel.user(String content, {String language = 'fr'}) =>
      MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
        language: language,
        type: MessageType.text,
      );

  factory MessageModel.assistant(
    String content, {
    String language = 'fr',
    String? logId,
    String action = 'RESPOND',
    String? dossierReference,
  }) =>
      MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
        language: language,
        type: MessageType.text,
        logId: logId,
        action: action,
        dossierReference: dossierReference,
      );

  factory MessageModel.voice({
    required String filePath,
    required int durationSec,
    String language = 'fr',
  }) =>
      MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '🎤 Message vocal',
        isUser: true,
        timestamp: DateTime.now(),
        language: language,
        type: MessageType.voice,
        filePath: filePath,
        durationSec: durationSec,
      );

  factory MessageModel.image({
    required String filePath,
    String language = 'fr',
  }) =>
      MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '🖼️ Image',
        isUser: true,
        timestamp: DateTime.now(),
        language: language,
        type: MessageType.image,
        filePath: filePath,
        fileName: filePath.split('/').last,
      );

  factory MessageModel.attachment({
    required String filePath,
    required String fileName,
    String language = 'fr',
  }) =>
      MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '📎 $fileName',
        isUser: true,
        timestamp: DateTime.now(),
        language: language,
        type: MessageType.file,
        filePath: filePath,
        fileName: fileName,
      );
}
