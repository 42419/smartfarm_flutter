import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_conversation.dart';
import 'supabase_service.dart';

class AiConversationService {
  AiConversationService._();

  static final AiConversationService instance = AiConversationService._();

  SupabaseClient? get _client => SupabaseService.maybeClient;

  Future<String> createConversation({
    required String userId,
    required String title,
    String? cozeConversationId,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase not initialized');

    final id = const Uuid().v4();
    await client.from('ai_conversations').insert({
      'id': id,
      'user_id': userId,
      'auth_user_id': userId,
      'title': title,
      'coze_conversation_id': cozeConversationId,
    });
    return id;
  }

  Future<void> updateConversation(
    String conversationId, {
    String? title,
    String? cozeConversationId,
  }) async {
    final client = _client;
    if (client == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (title != null) updates['title'] = title;
    if (cozeConversationId != null) {
      updates['coze_conversation_id'] = cozeConversationId;
    }

    try {
      await client.from('ai_conversations').update(updates).eq('id', conversationId);
    } catch (error) {
      debugPrint('updateConversation failed: $error');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('ai_conversations').delete().eq('id', conversationId);
    } catch (error) {
      debugPrint('deleteConversation failed: $error');
    }
  }

  Future<List<AiConversation>> fetchConversations(String userId) async {
    final client = _client;
    if (client == null) return const [];

    try {
      final rows = await client
          .from('ai_conversations')
          .select()
          .eq('auth_user_id', userId)
          .order('updated_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      return rows.map((row) => AiConversation.fromSupabase(row)).toList();
    } catch (error) {
      debugPrint('fetchConversations failed: $error');
      return const [];
    }
  }

  Future<void> saveMessage(String conversationId, String role, String content) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.from('ai_messages').insert({
        'conversation_id': conversationId,
        'role': role,
        'content': content,
      });

      await client.from('ai_conversations').update({
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', conversationId);
    } catch (error) {
      debugPrint('saveMessage failed: $error');
    }
  }

  Future<List<AiMessage>> fetchMessages(String conversationId) async {
    final client = _client;
    if (client == null) return const [];

    try {
      final rows = await client
          .from('ai_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .timeout(const Duration(seconds: 10));

      return rows.map((row) => AiMessage.fromSupabase(row)).toList();
    } catch (error) {
      debugPrint('fetchMessages failed: $error');
      return const [];
    }
  }
}

class Uuid {
  const Uuid();

  String v4() {
    final rng = Random();
    final r = List<int>.generate(16, (_) => rng.nextInt(256));
    r[6] = (r[6] & 0x0f) | 0x40;
    r[8] = (r[8] & 0x3f) | 0x80;
    return [
      r.sublist(0, 4),
      r.sublist(4, 6),
      r.sublist(6, 8),
      r.sublist(8, 10),
      r.sublist(10, 16),
    ].map((b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join()).join('-');
  }
}
