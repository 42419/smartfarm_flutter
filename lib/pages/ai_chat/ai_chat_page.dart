import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/ai_conversation.dart';
import '../../services/ai_conversation_service.dart';
import '../../services/auth_service.dart';
import '../../services/coze_service.dart';
import '../../services/device_manager.dart';
import 'models/chat_message.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/history_sheet.dart';
import 'widgets/message_bubble.dart';
import 'widgets/welcome_view.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  bool _isAiThinking = false;
  int? _reasoningMsgIndex;
  StreamSubscription<CozeStreamEvent>? _streamSub;
  bool _hasInputText = false;
  String? _currentConversationId;
  bool _autoScroll = true;

  static const _suggestions = [
    '如何提高作物产量？',
    '病虫害防治建议',
    '什么时候适合灌溉？',
    '如何判断是否缺肥？',
    '土壤湿度偏低怎么办？',
    '温度过高会有什么影响？',
    '湿度异常怎么调节？',
    '光照不足怎么补光？',
    '叶片发黄可能是什么原因？',
    '大棚通风要注意什么？',
    '作物长势差应该先排查什么？',
    '农作物常见病害怎么识别？',
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    _scrollController.addListener(_onScrollChanged);
  }

  void _onInputChanged() {
    final hasText = _inputController.text.trim().isNotEmpty;
    if (hasText != _hasInputText) {
      setState(() => _hasInputText = hasText);
    }
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 50;
    if (atBottom != _autoScroll) {
      setState(() => _autoScroll = atBottom);
    }
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _scrollController.removeListener(_onScrollChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _streamSub?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_autoScroll) return;
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

  String get _userId => AuthService.instance.currentUser?.id ?? 'anonymous';

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isAiThinking) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: text,
          isUser: true,
          time: DateTime.now(),
          isComplete: true,
        ),
      );
      _isAiThinking = true;
      _reasoningMsgIndex = _messages.length;
      _messages.add(
        ChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          content: '',
          isUser: false,
          time: DateTime.now(),
        ),
      );
    });
    _inputController.clear();
    _autoScroll = true;
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
        _currentConversationId!,
        'user',
        firstMessage,
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

  void _tryExecuteDeviceCommand(ChatMessage msg) {
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

    final dbMessages = await AiConversationService.instance.fetchMessages(
      conv.id,
    );

    _messages.clear();
    for (final msg in dbMessages) {
      final chatMsg = ChatMessage(
        id:
            msg.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
      _autoScroll = true;
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
      builder: (_) => HistorySheet(
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

  void _stopAi() {
    _streamSub?.cancel();
    _streamSub = null;
    if (_messages.isNotEmpty) {
      final lastMsg = _messages.last;
      if (!lastMsg.isUser && !lastMsg.isComplete) {
        setState(() {
          if (lastMsg.content.isEmpty) {
            lastMsg.content = '已停止生成';
          }
          lastMsg.isComplete = true;
          _isAiThinking = false;
          _reasoningMsgIndex = null;
        });
        _saveAiMessage(lastMsg.content);
        _saveCozeConversationId();
      }
    }
  }

  void _startNewChat({bool silent = false}) {
    _streamSub?.cancel();
    CozeService.instance.startNewChat();
    setState(() {
      _messages.clear();
      _isAiThinking = false;
      _reasoningMsgIndex = null;
      _currentConversationId = null;
      _autoScroll = true;
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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: '历史记录',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_outlined),
            tooltip: '新对话',
            onPressed: () => _startNewChat(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _messages.isEmpty
          ? WelcomeView(
              suggestions: _suggestions,
              colorScheme: colorScheme,
              isDark: isDark,
              onSuggestionTap: _onSuggestionTap,
              messages: _messages,
            )
          : _buildChatList(colorScheme, isDark),
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: ChatInputBar(
        controller: _inputController,
        focusNode: _inputFocus,
        isThinking: _isAiThinking,
        hasText: _hasInputText,
        onSend: _sendMessage,
        onStop: _stopAi,
      ),
    );
  }

  Widget _buildChatList(ColorScheme colorScheme, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return buildMessageBubble(
          _messages[index],
          index,
          colorScheme,
          isDark,
          _reasoningMsgIndex,
        );
      },
    );
  }
}
