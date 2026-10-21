import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/job.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_view.dart';

class ChatView extends StatefulWidget {
  final MatchItem match;
  final VoidCallback onBack;
  final ApiService? api;
  final String initialDraft;
  final ValueChanged<String>? onDraftChanged;

  const ChatView({
    super.key,
    required this.match,
    required this.onBack,
    this.api,
    this.initialDraft = '',
    this.onDraftChanged,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isFetching = false;
  int _messageRevision = 0;
  String? _loadError;
  String? _sendError;
  ApiService get _api => widget.api ?? ApiService.instance;
  Timer? _pollingTimer;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialDraft;
    _textController.addListener(_saveDraft);
    _loadMessages();
    // Poll for new messages every 4 seconds while in chat
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _loadMessages(silent: true),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.removeListener(_saveDraft);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveDraft() => widget.onDraftChanged?.call(_textController.text);

  Future<void> _loadMessages({bool silent = false}) async {
    if (_isFetching || _isSending) return;
    _isFetching = true;
    final revision = _messageRevision;
    if (!silent) setState(() => _isLoading = true);
    try {
      final messages = await _api.getConversation(widget.match.id);
      if (mounted && revision == _messageRevision) {
        setState(() {
          _messages = messages;
          _loadError = null;
        });
        if (!silent) _scrollToBottom();
      }
    } catch (_) {
      if (mounted && revision == _messageRevision) {
        setState(() => _loadError = 'Não foi possível atualizar a conversa.');
      }
    } finally {
      _isFetching = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageRevision++;
    setState(() {
      _isSending = true;
      _sendError = null;
    });

    try {
      final sentMessage = await _api.sendMessage(widget.match.id, text);
      if (mounted) {
        setState(() {
          _messages.removeWhere((message) => message.id == sentMessage.id);
          _messages.add(sentMessage);
          _loadError = null;
        });
        _textController.clear();
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _sendError =
              'Não foi possível confirmar o envio. Seu texto foi mantido.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.gray100)),
              ),
              child: Row(
                children: [
                  Tooltip(
                    message: 'Voltar para Matches',
                    child: InkWell(
                      onTap: widget.onBack,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.gray50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.chevronLeft,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gray100),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          widget.match.logo,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                LucideIcons.building,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Name & Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.match.company,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.match.title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.refreshCw,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => _loadMessages(),
                  ),
                ],
              ),
            ),

            // Message Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null && _messages.isEmpty
                  ? StatusView(
                      title: 'A conversa não carregou',
                      message: _loadError!,
                      actionLabel: 'Tentar novamente',
                      onAction: _loadMessages,
                      icon: LucideIcons.wifiOff,
                    )
                  : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.messageSquare,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Inicie a conversa!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Vocês deram match. Mande um olá!",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      children: [
                        ..._messages.map((msg) => _buildMessageBubble(msg)),
                      ],
                    ),
            ),

            if (_loadError != null && _messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'A conversa pode estar desatualizada.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadMessages,
                      child: const Text('Atualizar'),
                    ),
                  ],
                ),
              ),
            if (_sendError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _sendError!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _isSending ? null : _sendMessage,
                        child: const Text('Reenviar'),
                      ),
                    ],
                  ),
                ),
              ),
            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        enabled: !_isSending,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(fontSize: 16),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: "Escreva uma mensagem...",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar mensagem',
                    onPressed: _isSending ? null : _sendMessage,
                    icon: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isSending
                            ? AppColors.gray200
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                LucideIcons.send,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    // Current user message check
    final isMe = (msg.senderId != null && _api.currentUser?.id != null)
        ? (msg.senderId == _api.currentUser!.id)
        : (msg.sender == "candidate");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: Radius.circular(isMe ? 4 : 16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: const Radius.circular(16),
              ),
              border: isMe ? null : Border.all(color: AppColors.gray100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              msg.time,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
