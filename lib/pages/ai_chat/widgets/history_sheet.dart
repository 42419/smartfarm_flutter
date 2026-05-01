import 'package:flutter/material.dart';

import '../../../models/ai_conversation.dart';
import '../../../services/ai_conversation_service.dart';

class HistorySheet extends StatefulWidget {
  final String userId;
  final Future<void> Function(AiConversation) onSelect;
  final Future<void> Function(AiConversation) onDelete;
  final VoidCallback onNewChat;

  const HistorySheet({
    super.key,
    required this.userId,
    required this.onSelect,
    required this.onDelete,
    required this.onNewChat,
  });

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
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
      _conversations = await AiConversationService.instance.fetchConversations(
        widget.userId,
      );
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

  Color _avatarColor(int index, bool isDark, ColorScheme cs) {
    final colors = [
      cs.primary,
      cs.tertiary,
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    final base = colors[index % colors.length];
    return isDark ? base.withValues(alpha: 0.2) : base.withValues(alpha: 0.12);
  }

  Color _avatarTextColor(int index, bool isDark, ColorScheme cs) {
    final colors = [
      cs.primary,
      cs.tertiary,
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    return isDark
        ? colors[index % colors.length].withValues(alpha: 0.9)
        : colors[index % colors.length];
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.15),
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
                  icon: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    '新对话',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '暂无对话记录',
                              style: TextStyle(
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.35),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 72,
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.2),
                          ),
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
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 12,
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: colorScheme.onError,
                                  size: 24,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => widget.onSelect(conv),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: _avatarColor(
                                            index,
                                            isDark,
                                            colorScheme,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(
                                            conv.title.isNotEmpty
                                                ? conv.title[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: _avatarTextColor(
                                                index,
                                                isDark,
                                                colorScheme,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              conv.title,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.2),
                                        ),
                                        onPressed: () =>
                                            _handleDelete(conv),
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
}
