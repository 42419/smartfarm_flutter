import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../models/ai_conversation.dart';
import '../services/ai_conversation_service.dart';
import '../services/auth_service.dart';
import '../services/coze_service.dart';
import '../services/device_manager.dart';

class _ChatMessage {
  final String id;
  String content;
  final bool isUser;
  final DateTime time;
  String reasoningContent;
  bool isComplete;

  _ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.time,
    this.reasoningContent = '',
    this.isComplete = false,
  });
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  bool _isAiThinking = false;
  int? _reasoningMsgIndex;
  StreamSubscription<CozeStreamEvent>? _streamSub;
  bool _hasInputText = false;
  String? _currentConversationId;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    final hasText = _inputController.text.trim().isNotEmpty;
    if (hasText != _hasInputText) {
      setState(() => _hasInputText = hasText);
    }
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _streamSub?.cancel();
    super.dispose();
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

  String get _userId =>
      AuthService.instance.currentUser?.id ?? 'anonymous';

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isAiThinking) return;

    setState(() {
      _messages.add(_ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        isUser: true,
        time: DateTime.now(),
        isComplete: true,
      ));
      _isAiThinking = true;
      _reasoningMsgIndex = _messages.length;
      _messages.add(_ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: '',
        isUser: false,
        time: DateTime.now(),
      ));
    });
    _inputController.clear();
    _scrollToBottom();

    _ensureConversation(text);

    final aiMsgIndex = _messages.length - 1;
    final stream = CozeService.instance.sendMessage(_userId, text);
    _streamSub = stream.listen(
      (event) {
        if (!mounted) return;
        switch (event.type) {
          case CozeEventType.reasoning:
            setState(() {
              _messages[aiMsgIndex].reasoningContent += event.content ?? '';
            });
            _scrollToBottom();
            break;
          case CozeEventType.delta:
            setState(() {
              _messages[aiMsgIndex].content += event.content ?? '';
            });
            _scrollToBottom();
            break;
          case CozeEventType.completed:
            _saveAiMessage(event.content);
            _saveCozeConversationId();
            setState(() {
              _tryExecuteDeviceCommand(_messages[aiMsgIndex]);
              _messages[aiMsgIndex].isComplete = true;
              _isAiThinking = false;
              _reasoningMsgIndex = null;
            });
            _scrollToBottom();
            break;
          case CozeEventType.done:
            if (_isAiThinking) {
              _saveAiMessage(_messages[aiMsgIndex].content);
              _saveCozeConversationId();
              setState(() {
                _tryExecuteDeviceCommand(_messages[aiMsgIndex]);
                _messages[aiMsgIndex].isComplete = true;
                _isAiThinking = false;
                _reasoningMsgIndex = null;
              });
            }
            break;
          case CozeEventType.error:
            setState(() {
              _messages[aiMsgIndex].content = '请求失败: ${event.error}';
              _messages[aiMsgIndex].isComplete = true;
              _isAiThinking = false;
              _reasoningMsgIndex = null;
            });
            break;
          case CozeEventType.deviceControl:
            break;
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _messages[aiMsgIndex].content = '网络错误: $err';
          _messages[aiMsgIndex].isComplete = true;
          _isAiThinking = false;
          _reasoningMsgIndex = null;
        });
      },
      onDone: () {
        if (!mounted) return;
        if (_isAiThinking) {
          _saveAiMessage(_messages[aiMsgIndex].content);
          _saveCozeConversationId();
          setState(() {
            _tryExecuteDeviceCommand(_messages[aiMsgIndex]);
            _messages[aiMsgIndex].isComplete = true;
            _isAiThinking = false;
            _reasoningMsgIndex = null;
          });
        }
      },
    );
  }

  void _ensureConversation(String firstMessage) {
    if (_currentConversationId != null) {
      AiConversationService.instance.saveMessage(
        _currentConversationId!, 'user', firstMessage,
      );
      return;
    }
    final userId = _userId;
    if (userId == 'anonymous') return;

    final title = firstMessage.length > 30
        ? '${firstMessage.substring(0, 30)}...'
        : firstMessage;

    AiConversationService.instance
        .createConversation(userId: userId, title: title)
        .then((id) {
      _currentConversationId = id;
      AiConversationService.instance.saveMessage(id, 'user', firstMessage);
    }).catchError((_) {});
  }

  void _saveAiMessage(String? content) {
    if (_currentConversationId == null || content == null || content.isEmpty) {
      return;
    }
    AiConversationService.instance.saveMessage(
      _currentConversationId!,
      'assistant',
      content,
    );
  }

  void _saveCozeConversationId() {
    if (_currentConversationId == null) return;
    final cozeId = CozeService.instance.conversationId;
    if (cozeId != null) {
      AiConversationService.instance.updateConversation(
        _currentConversationId!,
        cozeConversationId: cozeId,
      );
    }
  }

  void _tryExecuteDeviceCommand(_ChatMessage msg) {
    final content = msg.content;
    final match = RegExp(
      r'^(\{.*?"action"\s*:\s*"device_control".*?\})\s*',
    ).firstMatch(content);
    if (match == null) return;

    try {
      final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      if (json['action'] != 'device_control') return;

      final device = json['device']?.toString() ?? '';
      final command = json['command']?.toString() ?? '';

      String? commandName;
      if (device == 'fan') {
        commandName = 'motor_control';
      } else if (device == 'light') {
        commandName = 'light_control';
      }
      final switchName = command == 'on' ? 'ON' : 'OFF';

      if (commandName != null) {
        DeviceManager.instance.controlDevice(commandName, switchName);
      }

      msg.content = content.substring(match.end).trim();
    } catch (_) {}
  }

  Future<void> _loadConversation(AiConversation conv) async {
    _streamSub?.cancel();
    CozeService.instance.startNewChat();

    final dbMessages =
        await AiConversationService.instance.fetchMessages(conv.id);

    _messages.clear();
    for (final msg in dbMessages) {
      final chatMsg = _ChatMessage(
        id: msg.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        content: msg.content,
        isUser: msg.role == 'user',
        time: msg.createdAt,
        isComplete: true,
      );
      if (msg.role == 'assistant') {
        _tryExecuteDeviceCommand(chatMsg);
      }
      _messages.add(chatMsg);
    }

    if (conv.cozeConversationId != null) {
      CozeService.instance.resumeConversation(conv.cozeConversationId!);
    }
    CozeService.instance.loadHistory(
      dbMessages.map((m) => m.toChatHistory()).toList(),
    );

    _currentConversationId = conv.id;

    if (mounted) {
      setState(() {});
      Navigator.of(context).pop();
      _scrollToBottom();
    }
  }

  Future<void> _deleteConversation(AiConversation conv) async {
    await AiConversationService.instance.deleteConversation(conv.id);
    if (_currentConversationId == conv.id) {
      _startNewChat(silent: true);
    }
  }

  void _openHistory() {
    final userId = _userId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorySheet(
        userId: userId,
        onSelect: _loadConversation,
        onDelete: _deleteConversation,
        onNewChat: () {
          Navigator.of(context).pop();
          _startNewChat();
        },
      ),
    );
  }

  void _onSuggestionTap(String prompt) {
    _inputController.text = prompt;
    _sendMessage();
  }

  void _startNewChat({bool silent = false}) {
    _streamSub?.cancel();
    CozeService.instance.startNewChat();
    setState(() {
      _messages.clear();
      _isAiThinking = false;
      _reasoningMsgIndex = null;
      _currentConversationId = null;
    });
    if (!silent) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '历史记录',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: '新对话',
            onPressed: () => _startNewChat(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _messages.isEmpty
          ? _buildWelcomeView(colorScheme, isDark)
          : _buildChatList(colorScheme, isDark),
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: _ChatInputBar(
        controller: _inputController,
        focusNode: _inputFocus,
        isThinking: _isAiThinking,
        hasText: _hasInputText,
        onSend: _sendMessage,
      ),
    );
  }

  Widget _buildWelcomeView(ColorScheme colorScheme, bool isDark) {
    final suggestions = [
      '今天大棚环境怎么样？',
      '最近一周温度趋势如何？',
      '帮我分析一下土壤数据',
      '如何提高作物产量？',
      '当前设备运行状态总览',
      '病虫害防治建议',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            '你好，我是禾寻 AI',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '你的智能农业助手，随时为你解答',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '试试这样问我',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () => _onSuggestionTap(s),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildChatList(ColorScheme colorScheme, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index], index, colorScheme, isDark);
      },
    );
  }

  Widget _buildMessageBubble(
    _ChatMessage msg,
    int index,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isStreaming = !msg.isUser && !msg.isComplete && msg.content.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            _buildAvatar(colorScheme, false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (msg.reasoningContent.isNotEmpty)
                  _buildReasoningSection(
                      msg, index, colorScheme, isDark),
                if (!isStreaming)
                  _buildBubble(msg, colorScheme, isDark)
                else
                  _buildThinkingBubble(colorScheme, isDark),
              ],
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(colorScheme, true),
          ],
        ],
      ),
    );
  }

  Widget _buildReasoningSection(
    _ChatMessage msg,
    int index,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isReasoningCurrent =
        index == _reasoningMsgIndex && msg.content.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: _ReasoningCard(
        content: msg.reasoningContent,
        isThinking: isReasoningCurrent,
        isDark: isDark,
        colorScheme: colorScheme,
      ),
    );
  }

  Widget _buildBubble(
      _ChatMessage msg, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: msg.isUser
            ? colorScheme.primary
            : isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft:
              msg.isUser ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight:
              msg.isUser ? const Radius.circular(4) : const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.content.isNotEmpty)
            msg.isUser
                ? Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onPrimary,
                      height: 1.5,
                    ),
                  )
                : MarkdownBody(
                    data: msg.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                      code: TextStyle(
                        fontSize: 13,
                        backgroundColor: isDark
                            ? Colors.white12
                            : Colors.black12,
                        color: colorScheme.onSurface,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: colorScheme.primary.withOpacity(0.4),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
          const SizedBox(height: 4),
          Text(
            '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 11,
              color: msg.isUser
                  ? colorScheme.onPrimary.withOpacity(0.6)
                  : colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: const _TypingDots(),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, bool isUser) {
    if (isUser) {
      final avatarUrl = AuthService.instance.currentUser?.avatarUrl;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(avatarUrl),
        );
      }
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isUser ? colorScheme.primaryContainer : colorScheme.tertiaryContainer,
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: isUser ? colorScheme.primary : colorScheme.tertiary,
      ),
    );
}

}

class _ChatInputBar extends StatelessWidget {
  _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isThinking,
    required this.hasText,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isThinking;
  final bool hasText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).padding.bottom +
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '向 AI 提问...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.35),
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasText
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.1),
            ),
            child: IconButton(
              onPressed: isThinking ? null : onSend,
              icon: Icon(
                isThinking ? Icons.stop : Icons.arrow_upward,
                color: hasText
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withOpacity(0.3),
                size: 22,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasoningCard extends StatefulWidget {
  final String content;
  final bool isThinking;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ReasoningCard({
    required this.content,
    required this.isThinking,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  State<_ReasoningCard> createState() => _ReasoningCardState();
}

class _ReasoningCardState extends State<_ReasoningCard> {
  bool _expanded = true;

  @override
  void didUpdateWidget(covariant _ReasoningCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isThinking && !widget.isThinking) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? widget.colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : widget.colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isThinking)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                      ),
                    )
                  else
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: widget.colorScheme.primary.withOpacity(0.7),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isThinking ? '正在思考...' : '思考过程',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 16,
                      color: widget.colorScheme.onSurface.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _expanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      widget.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.colorScheme.onSurface.withOpacity(0.55),
                        height: 1.6,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.4 + 0.6 * (0.5 - 0.5 * _cos(t * 2 * 3.14159));
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _cos(double x) => (1 - (x - 1) * (x - 1)).clamp(0.0, 1.0);
}

class _HistorySheet extends StatefulWidget {
  const _HistorySheet({
    required this.userId,
    required this.onSelect,
    required this.onDelete,
    required this.onNewChat,
  });

  final String userId;
  final Future<void> Function(AiConversation) onSelect;
  final Future<void> Function(AiConversation) onDelete;
  final VoidCallback onNewChat;

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  List<AiConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      _conversations =
          await AiConversationService.instance.fetchConversations(widget.userId);
    } catch (_) {
      _conversations = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleDelete(AiConversation conv) async {
    final index = _conversations.indexOf(conv);
    setState(() => _conversations.remove(conv));
    await widget.onDelete(conv);
    if (mounted && index < _conversations.length) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Icon(Icons.history, size: 22, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  '对话记录',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onNewChat,
                  icon: Icon(Icons.add_rounded, size: 18, color: colorScheme.primary),
                  label: Text('新对话', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: colorScheme.onSurface.withOpacity(0.15)),
                            const SizedBox(height: 12),
                            Text('暂无对话记录', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.35), fontSize: 15)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: colorScheme.outlineVariant.withOpacity(0.2)),
                          itemBuilder: (context, index) {
                            final conv = _conversations[index];
                            final timeStr = _formatTime(conv.updatedAt);
                            return Dismissible(
                              key: Key(conv.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                _handleDelete(conv);
                                return false;
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                child: Icon(Icons.delete_outline, color: colorScheme.onError, size: 24),
                              ),
                              child: InkWell(
                                onTap: () => widget.onSelect(conv),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: _avatarColor(index, isDark, colorScheme),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(
                                            conv.title.isNotEmpty ? conv.title[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: _avatarTextColor(index, isDark, colorScheme),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              conv.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme.onSurface.withOpacity(0.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.onSurface.withOpacity(0.2)),
                                        onPressed: () => _handleDelete(conv),
                                        splashRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Color _avatarColor(int index, bool isDark, ColorScheme cs) {
    final colors = [
      cs.primary, cs.tertiary, const Color(0xFF4CAF50),
      const Color(0xFFFF9800), const Color(0xFF9C27B0), const Color(0xFF00BCD4),
    ];
    final base = colors[index % colors.length];
    return isDark ? base.withOpacity(0.2) : base.withOpacity(0.12);
  }

  Color _avatarTextColor(int index, bool isDark, ColorScheme cs) {
    final colors = [
      cs.primary, cs.tertiary, const Color(0xFF4CAF50),
      const Color(0xFFFF9800), const Color(0xFF9C27B0), const Color(0xFF00BCD4),
    ];
    return isDark ? colors[index % colors.length].withOpacity(0.9) : colors[index % colors.length];
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    final sameYear = time.year == now.year;
    return sameYear
        ? '${time.month}月${time.day}日'
        : '${time.year}年${time.month}月${time.day}日';
  }
}
