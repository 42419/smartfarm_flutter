class ChatMessage {
  final String id;
  String content;
  final bool isUser;
  final DateTime time;
  String reasoningContent;
  bool isComplete;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.time,
    this.reasoningContent = '',
    this.isComplete = false,
  });
}
