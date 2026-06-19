import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../providers/assistant_provider.dart';
import '../../domain/models/message_model.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/markdown_text.dart';
import '../../../../shared/widgets/upload_document_card.dart'
    show DocumentUploadHelper;

/// Chat Ndiogoye — design repris du prototype (avatar animé, suggestions,
/// bulles dégradées, indicateur de frappe). Branché sur assistantProvider.
class AgentChatScreen extends ConsumerStatefulWidget {
  const AgentChatScreen({super.key});

  @override
  ConsumerState<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends ConsumerState<AgentChatScreen> {
  final _textCtr = TextEditingController();
  final _scrollCtr = ScrollController();
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechReady = false;

  static const _suggestions = [
    'Quels documents pour un extrait de naissance ?',
    'Comment régulariser un terrain (foncier) ?',
    'Comment prendre un rendez-vous à la mairie ?',
    'Quels sont les frais et les délais ?',
  ];

  @override
  void initState() {
    super.initState();
    _textCtr.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _speech.stop();
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

  /// Envoie une image à Ndiogoye (vision via image_base64).
  Future<void> _sendImage(String? path) async {
    if (path == null) return;
    await ref.read(assistantProvider.notifier).sendMessage('', imagePath: path);
    _scrollToBottom();
  }

  /// « + » : importer un document existant depuis la galerie.
  Future<void> _uploadDocument() async {
    _sendImage(await DocumentUploadHelper.pickFromGallery(context));
  }

  /// 📷 : prendre une photo d'un document.
  Future<void> _takePhoto() async {
    _sendImage(await DocumentUploadHelper.pickFromCamera(context));
  }

  /// Dictée vocale : démarre/arrête l'écoute et écrit le texte reconnu.
  /// Tout est protégé : si la reconnaissance échoue (web sans micro, plugin
  /// absent…), on affiche un message au lieu de rester silencieux.
  Future<void> _toggleMic() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    try {
      if (!_speechReady) {
        _speechReady = await _speech.initialize(
          onStatus: (s) {
            if ((s == 'done' || s == 'notListening') && mounted) {
              setState(() => _isListening = false);
            }
          },
          onError: (e) {
            if (mounted) {
              setState(() => _isListening = false);
              _micUnavailable(e.errorMsg);
            }
          },
        );
      }
      if (!_speechReady) {
        _micUnavailable();
        return;
      }
      setState(() => _isListening = true);
      await _speech.listen(
        listenOptions: SpeechListenOptions(localeId: 'fr_FR'),
        onResult: (r) => setState(() {
          _textCtr.text = r.recognizedWords;
          _textCtr.selection =
              TextSelection.collapsed(offset: _textCtr.text.length);
        }),
      );
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
      _micUnavailable();
    }
  }

  void _micUnavailable([String? detail]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(detail != null && detail.isNotEmpty
          ? 'Micro : $detail'
          : 'Micro indisponible. Sur le web, utilisez Chrome et autorisez le microphone.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);
    final user = ref.watch(authProvider).user;
    final userName = user?.prenom ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── HEADER DÉGRADÉ (monte derrière la status bar) ──────────
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x330B285D),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 16, 20, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const AnimatedNdiogoye(size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ndiogoye',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Votre assistant personnel',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        ref.read(assistantProvider.notifier).clearHistory(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // ── MESSAGES ──────────────────────────────────────
            Expanded(
              child: state.messages.isEmpty
                  ? _SuggestionsView(
                      suggestions: _suggestions,
                      onTap: _send,
                      userName: userName,
                    )
                  : ListView.builder(
                      controller: _scrollCtr,
                      padding: const EdgeInsets.all(20),
                      itemCount:
                          state.messages.length + (state.isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == state.messages.length && state.isLoading) {
                          return const _TypingIndicator();
                        }
                        final m = state.messages[i];
                        return _MessageBubble(
                          msg: m,
                          onFeedback: (rating) => ref
                              .read(assistantProvider.notifier)
                              .submitFeedback(m.id, rating),
                          onViewDossiers: () =>
                              context.go(AppRoutes.dossiers),
                        );
                      },
                    ),
            ),

            // ── ZONE SAISIE ──────────────────────────────────────
            _InputBar(
              controller: _textCtr,
              isLoading: state.isLoading,
              isListening: _isListening,
              onSend: _send,
              onMic: _toggleMic,
              onUpload: _uploadDocument,
              onCamera: _takePhoto,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsView extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  final String userName;

  const _SuggestionsView({
    required this.suggestions,
    required this.onTap,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const AnimatedNdiogoye(size: 100),
                const SizedBox(height: 16),
                Text(
                  'Salam $userName ! Je suis Ndiogoye',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Comment puis-je t'aider aujourd'hui ?",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Suggestions de questions',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...suggestions.map((s) => GestureDetector(
                onTap: () => onTap(s),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 16, color: Color(0xFF0EA5E9)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final void Function(int rating)? onFeedback;
  final VoidCallback? onViewDossiers;

  const _MessageBubble({
    required this.msg,
    this.onFeedback,
    this.onViewDossiers,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    final showActions = !isUser &&
        msg.action == 'SHOW_PAYMENT_AND_DOSSIER' &&
        msg.dossierReference != null;
    final showFeedback = !isUser && msg.logId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const AnimatedNdiogoye(size: 32),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? null : Colors.white,
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: isUser
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: isUser
                      ? Text(
                          msg.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        )
                      : MarkdownText(
                          msg.content,
                          color: const Color(0xFF1E293B),
                          fontSize: 14,
                          height: 1.4,
                        ),
                ),
                if (showActions)
                  _DossierActionCard(
                    reference: msg.dossierReference!,
                    onViewDossiers: onViewDossiers,
                  ),
                if (showFeedback)
                  _FeedbackRow(
                    rating: msg.feedbackRating,
                    onFeedback: onFeedback,
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Carte affichée quand Ndiogoye a créé un dossier (action
/// SHOW_PAYMENT_AND_DOSSIER) : référence + paiement + accès au dossier.
class _DossierActionCard extends StatelessWidget {
  final String reference;
  final VoidCallback? onViewDossiers;

  const _DossierActionCard({required this.reference, this.onViewDossiers});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3E4FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open_rounded,
                  color: Color(0xFF1B4A9C), size: 18),
              const SizedBox(width: 8),
              Text(
                'Dossier créé : $reference',
                style: const TextStyle(
                  color: Color(0xFF0B285D),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Réglez les frais (Wave ou Orange Money) puis suivez votre dossier.',
            style: TextStyle(color: Color(0xFF475569), fontSize: 12),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewDossiers,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Payer & voir le dossier',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boutons 👍 / 👎 sous une réponse de Ndiogoye (endpoint feedback).
class _FeedbackRow extends StatelessWidget {
  final int rating; // 0 = non noté, 1 = 👍, -1 = 👎
  final void Function(int rating)? onFeedback;

  const _FeedbackRow({required this.rating, this.onFeedback});

  @override
  Widget build(BuildContext context) {
    if (rating != 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(
          children: [
            Icon(
              rating == 1
                  ? Icons.thumb_up_rounded
                  : Icons.thumb_down_rounded,
              size: 14,
              color: rating == 1
                  ? const Color(0xFF10B981)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            const Text(
              'Merci pour votre retour',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        children: [
          _FeedbackButton(
            icon: Icons.thumb_up_outlined,
            onTap: () => onFeedback?.call(1),
          ),
          const SizedBox(width: 4),
          _FeedbackButton(
            icon: Icons.thumb_down_outlined,
            onTap: () => onFeedback?.call(-1),
          ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FeedbackButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const AnimatedNdiogoye(size: 32),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Row(
              children: [
                _Dot(delay: 0),
                SizedBox(width: 4),
                _Dot(delay: 200),
                SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_ctrl.value * 0.7),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF94A3B8), shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isListening;
  final void Function(String) onSend;
  final VoidCallback onMic;
  final VoidCallback onUpload; // « + » : importer un document (galerie)
  final VoidCallback onCamera; // 📷 : prendre une photo

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.isListening,
    required this.onSend,
    required this.onMic,
    required this.onUpload,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 12 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // « + » : importer un document existant (galerie)
          _RoundIcon(
            icon: Icons.add_rounded,
            onTap: onUpload,
            iconColor: const Color(0xFF1B4A9C),
            bg: const Color(0xFFEFF3FA),
            size: 44,
          ),
          const SizedBox(width: 8),
          // Champ « pilule »
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: controller,
                maxLines: 5,
                minLines: 1,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      isListening ? 'Parlez, je vous écoute…' : 'Message…',
                  hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: onSend,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 📷 : prendre une photo d'un document
          _RoundIcon(
            icon: Icons.photo_camera_rounded,
            onTap: onCamera,
            iconColor: const Color(0xFF64748B),
            bg: Colors.transparent,
            size: 44,
          ),
          // Micro (toujours visible) → bascule en bouton « envoyer » si on tape
          if (hasText)
            _RoundIcon(
              icon: Icons.send_rounded,
              onTap: isLoading ? null : () => onSend(controller.text),
              iconColor: Colors.white,
              bg: isLoading
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF0B285D),
              size: 44,
              loading: isLoading,
            )
          else
            _RoundIcon(
              icon: isListening ? Icons.stop_rounded : Icons.mic_rounded,
              onTap: onMic,
              iconColor:
                  isListening ? Colors.white : const Color(0xFF64748B),
              bg: isListening ? const Color(0xFFEF4444) : Colors.transparent,
              size: 44,
            ),
        ],
      ),
    );
  }
}

/// Bouton circulaire tappable de manière fiable (HitTestBehavior.opaque) —
/// utilisé pour « + », caméra, micro et envoyer dans la barre de saisie.
class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color bg;
  final double size;
  final bool loading;

  const _RoundIcon({
    required this.icon,
    required this.onTap,
    required this.iconColor,
    required this.bg,
    this.size = 44,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF64748B)),
                ),
              )
            : Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class AnimatedNdiogoye extends StatefulWidget {
  final double size;
  const AnimatedNdiogoye({super.key, this.size = 48});

  @override
  State<AnimatedNdiogoye> createState() => _AnimatedNdiogoyeState();
}

class _AnimatedNdiogoyeState extends State<AnimatedNdiogoye>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4, end: 4)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B285D).withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
              image: const DecorationImage(
                image: AssetImage('assets/images/ndiogoye.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}
