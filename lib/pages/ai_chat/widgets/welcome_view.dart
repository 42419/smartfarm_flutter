import 'package:flutter/material.dart';

import '../models/chat_message.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({
    super.key,
    required this.suggestions,
    required this.colorScheme,
    required this.isDark,
    required this.onSuggestionTap,
    this.messages,
  });

  final List<String> suggestions;
  final ColorScheme colorScheme;
  final bool isDark;
  final ValueChanged<String> onSuggestionTap;
  final List<ChatMessage>? messages;

  bool get _shouldShow => messages == null || messages!.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                SizedBox(height: constraints.maxHeight * 0.12),
                Container(
                  width: 150,
                  height: 150,
                  decoration:
                      const BoxDecoration(shape: BoxShape.circle),
                  child: Image.asset(
                    "assets/img/ai.png",
                    width: 200,
                    height: 200,
                  ),
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
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSuggestionGrid(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionGrid() {
    return SizedBox(
      height: 40.0 * 3 + 8.0 * 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          direction: Axis.vertical,
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) {
            return GestureDetector(
              onTap: () => onSuggestionTap(s),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
