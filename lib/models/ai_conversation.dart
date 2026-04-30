class AiConversation {
  final String id;
  final String userId;
  final String? authUserId;
  final String title;
  final String? cozeConversationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiConversation({
    required this.id,
    required this.userId,
    this.authUserId,
    required this.title,
    this.cozeConversationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiConversation.fromSupabase(Map<String, dynamic> row) {
    return AiConversation(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      authUserId: row['auth_user_id']?.toString(),
      title: row['title']?.toString() ?? '新对话',
      cozeConversationId: row['coze_conversation_id']?.toString(),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      if (authUserId != null) 'auth_user_id': authUserId,
      'title': title,
      'coze_conversation_id': cozeConversationId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}

class AiMessage {
  final int? id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime createdAt;

  const AiMessage({
    this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AiMessage.fromSupabase(Map<String, dynamic> row) {
    return AiMessage(
      id: row['id'] is int ? row['id'] as int : int.tryParse(row['id']?.toString() ?? ''),
      conversationId: row['conversation_id']?.toString() ?? '',
      role: row['role']?.toString() ?? '',
      content: row['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      if (id != null) 'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toChatHistory() {
    return {
      'content': content,
      'content_type': 'text',
      'role': role,
      'type': role == 'user' ? 'question' : 'answer',
    };
  }
}
