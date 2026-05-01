import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../services/auth_service.dart';
import '../models/chat_message.dart';
import 'reasoning_card.dart';
import 'typing_dots.dart';

Widget buildMessageBubble(
  ChatMessage msg,
  int index,
  ColorScheme colorScheme,
  bool isDark,
  int? reasoningMsgIndex,
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
          buildAvatar(colorScheme, false),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: msg.isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (msg.reasoningContent.isNotEmpty)
                _buildReasoningSection(msg, index, colorScheme, isDark, reasoningMsgIndex),
              if (!isStreaming)
                _buildBubble(msg, colorScheme, isDark)
              else
                _buildThinkingBubble(colorScheme, isDark),
            ],
          ),
        ),
        if (msg.isUser) ...[
          const SizedBox(width: 8),
          buildAvatar(colorScheme, true),
        ],
      ],
    ),
  );
}

Widget _buildReasoningSection(
  ChatMessage msg,
  int index,
  ColorScheme colorScheme,
  bool isDark,
  int? reasoningMsgIndex,
) {
  final isReasoningCurrent =
      index == reasoningMsgIndex && msg.content.isEmpty;
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: ReasoningCard(
      content: msg.reasoningContent,
      isThinking: isReasoningCurrent,
      isDark: isDark,
      colorScheme: colorScheme,
    ),
  );
}

Widget _buildBubble(ChatMessage msg, ColorScheme colorScheme, bool isDark) {
  final isUser = msg.isUser;
  final bgColor = isUser
      ? colorScheme.primaryContainer
      : isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainerLow;
  final textColor =
      isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft:
            isUser ? const Radius.circular(18) : const Radius.circular(4),
        bottomRight:
            isUser ? const Radius.circular(4) : const Radius.circular(18),
      ),
    ),
    child: msg.content.isNotEmpty
        ? isUser
            ? Text(
                msg.content,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  height: 1.5,
                ),
              )
            : MarkdownBody(
                data: msg.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    height: 1.5,
                  ),
                  code: TextStyle(
                    fontSize: 13,
                    backgroundColor:
                        isDark ? Colors.white12 : Colors.black12,
                    color: textColor,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              )
        : const SizedBox.shrink(),
  );
}

Widget _buildThinkingBubble(ColorScheme colorScheme, bool isDark) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainerLow,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomRight: Radius.circular(18),
        bottomLeft: Radius.circular(4),
      ),
    ),
    child: const TypingDots(),
  );
}

Widget buildAvatar(ColorScheme colorScheme, bool isUser) {
  if (isUser) {
    final avatarUrl = AuthService.instance.currentUser?.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        size: 18,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
  return CircleAvatar(
    radius: 16,
    backgroundColor: colorScheme.tertiaryContainer,
    backgroundImage: const AssetImage('assets/img/ai.png'),
  );
}
