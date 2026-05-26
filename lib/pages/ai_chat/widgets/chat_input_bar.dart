import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isThinking,
    required this.hasText,
    required this.onSend,
    required this.onStop,
    this.isListening = false,
    this.onMicTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isThinking;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool isListening;
  final VoidCallback? onMicTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottom =
        MediaQuery.of(context).padding.bottom +
            MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
      decoration: BoxDecoration(color: colorScheme.surface),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (onMicTap != null)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: GestureDetector(
                onTap: onMicTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening
                        ? Colors.redAccent
                        : colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none_outlined,
                    size: 22,
                    color: isListening
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isListening
                    ? Colors.redAccent.withValues(alpha: 0.08)
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(28),
                border: isListening
                    ? Border.all(color: Colors.redAccent.withValues(alpha: 0.3))
                    : null,
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: isListening ? '正在聆听...' : '向 AI 提问...',
                  hintStyle: TextStyle(
                    color: isListening
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
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
                  : colorScheme.surfaceContainerHighest,
            ),
            child: IconButton(
              onPressed: isThinking ? onStop : onSend,
              icon: Icon(
                isThinking ? Icons.stop : Icons.arrow_upward,
                color: hasText
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withValues(alpha: 0.4),
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
