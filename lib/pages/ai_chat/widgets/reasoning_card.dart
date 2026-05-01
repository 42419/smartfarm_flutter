import 'package:flutter/material.dart';

class ReasoningCard extends StatefulWidget {
  final String content;
  final bool isThinking;
  final bool isDark;
  final ColorScheme colorScheme;

  const ReasoningCard({
    super.key,
    required this.content,
    required this.isThinking,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  State<ReasoningCard> createState() => _ReasoningCardState();
}

class _ReasoningCardState extends State<ReasoningCard> {
  bool _expanded = true;

  @override
  void didUpdateWidget(covariant ReasoningCard oldWidget) {
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
            ? widget.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
            : widget.colorScheme.secondaryContainer.withValues(alpha: 0.3),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isThinking)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  else
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color:
                          widget.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isThinking ? '正在思考...' : '思考过程',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          widget.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 16,
                      color: widget.colorScheme.onSurface
                          .withValues(alpha: 0.35),
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
                    padding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      widget.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.colorScheme.onSurface
                            .withValues(alpha: 0.55),
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
