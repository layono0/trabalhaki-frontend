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

  /// Candidates can only reply after the company sends the first message.
  bool get _awaitingCompanyFirstMessage => _messages.isEmpty;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialDraft;
    _textController.addListener(_saveDraft);
    _loadMessages();
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
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_awaitingCompanyFirstMessage) return;
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
    final inputBlocked = _isLoading || _isSending || _awaitingCompanyFirstMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton.outlined(
                    tooltip: 'Voltar para Matches',
                    onPressed: widget.onBack,
                    icon: const Icon(LucideIcons.chevronLeft, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Company Logo Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      widget.match.logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        LucideIcons.building,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
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
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
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
                    tooltip: 'Atualizar conversa',
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.lg),
                              ),
                              child: const Icon(
                                LucideIcons.clock,
                                size: 30,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aguardando a empresa iniciar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No Trabalhaki, a empresa envia a primeira mensagem após o match. Assim que ${widget.match.company} escrever, você poderá responder por aqui.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
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

            // Input Bar (locked cleanly until company sends first message)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _awaitingCompanyFirstMessage
                            ? AppColors.surfaceMuted
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _textController,
                        enabled: !inputBlocked,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(fontSize: 15),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          filled: false,
                          hintText: _awaitingCompanyFirstMessage
                              ? 'Aguardando a primeira mensagem da empresa...'
                              : 'Escreva uma mensagem...',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                          prefixIcon: _awaitingCompanyFirstMessage
                              ? const Icon(
                                  LucideIcons.lock,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: _awaitingCompanyFirstMessage
                        ? 'Aguardando a empresa iniciar'
                        : 'Enviar mensagem',
                    onPressed: inputBlocked ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      minimumSize: const Size(44, 44),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            LucideIcons.send,
                            color: inputBlocked
                                ? AppColors.textSecondary
                                : Colors.white,
                            size: 18,
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
    final isMe = (msg.senderId != null && _api.currentUser?.id != null)
        ? (msg.senderId == _api.currentUser!.id)
        : (msg.sender == 'candidate');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadii.lg),
                topRight: Radius.circular(isMe ? 4 : AppRadii.lg),
                bottomLeft: Radius.circular(isMe ? AppRadii.lg : 4),
                bottomRight: const Radius.circular(AppRadii.lg),
              ),
              border: isMe ? null : Border.all(color: AppColors.border),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              msg.time,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
