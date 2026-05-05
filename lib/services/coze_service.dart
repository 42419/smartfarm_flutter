import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/config.dart';
import 'device_manager.dart';

enum CozeEventType { delta, reasoning, completed, done, error, deviceControl }

class CozeStreamEvent {
  final CozeEventType type;
  final String? content;
  final String? conversationId;
  final String? error;

  const CozeStreamEvent({
    required this.type,
    this.content,
    this.conversationId,
    this.error,
  });
}

class CozeService {
  CozeService._();

  static final CozeService instance = CozeService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
  ));

  String? _conversationId;
  final List<Map<String, dynamic>> _chatHistory = [];
  static const int _maxHistoryItems = 20;

  String? get conversationId => _conversationId;

  void startNewChat() {
    _conversationId = null;
    _chatHistory.clear();
  }

  void resumeConversation(String cozeConversationId) {
    _conversationId = cozeConversationId;
  }

  void loadHistory(List<Map<String, dynamic>> messages) {
    _chatHistory.clear();
    _chatHistory.addAll(messages);
  }

  Stream<CozeStreamEvent> sendMessage(String userId, String content) {
    final controller = StreamController<CozeStreamEvent>();

    _send(controller, userId, content);

    return controller.stream;
  }

  Future<void> _send(
    StreamController<CozeStreamEvent> controller,
    String userId,
    String content,
  ) async {
    _chatHistory.add({
      'content': content,
      'content_type': 'text',
      'role': 'user',
      'type': 'question',
    });

    final recentHistory = _chatHistory.length > _maxHistoryItems
        ? _chatHistory.sublist(_chatHistory.length - _maxHistoryItems)
        : _chatHistory.toList();

    final sensorCtx = _buildSensorContext();
    if (sensorCtx != null) {
      recentHistory.insert(0, sensorCtx);
    }

    final body = <String, dynamic>{
      'bot_id': Config.cozeBotId,
      'user_id': userId,
      'stream': true,
      'auto_save_history': true,
      'additional_messages': recentHistory,
      'parameters': {},
    };

    if (_conversationId != null) {
      body['conversation_id'] = _conversationId;
    }

    try {
      final response = await _dio.post(
        Config.cozeApiUrl,
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer ${Config.cozeApiToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final stream = response.data.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String currentEvent = '';
      String currentData = '';

      await for (final line in stream) {
        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          currentData = line.substring(5).trim();
          if (currentData == '[DONE]') {
            controller.add(const CozeStreamEvent(type: CozeEventType.done));
            continue;
          }

          try {
            final json = jsonDecode(currentData) as Map<String, dynamic>;

            switch (currentEvent) {
              case 'conversation.chat.created':
                _conversationId = json['conversation_id']?.toString();
                break;

              case 'conversation.message.delta':
                final reasoning =
                    json['reasoning_content']?.toString() ?? '';
                final deltaContent = json['content']?.toString() ?? '';

                if (reasoning.isNotEmpty) {
                  controller.add(CozeStreamEvent(
                    type: CozeEventType.reasoning,
                    content: reasoning,
                  ));
                }
                if (deltaContent.isNotEmpty) {
                  controller.add(CozeStreamEvent(
                    type: CozeEventType.delta,
                    content: deltaContent,
                  ));
                }
                break;

              case 'conversation.message.completed':
                final msgType = json['type']?.toString() ?? '';
                if (msgType == 'answer') {
                  final answerContent = json['content']?.toString() ?? '';
                  _chatHistory.add({
                    'content': answerContent,
                    'content_type': 'text',
                    'role': 'assistant',
                    'type': 'answer',
                  });
                  controller.add(CozeStreamEvent(
                    type: CozeEventType.completed,
                    content: answerContent,
                    conversationId: _conversationId,
                  ));
                }
                break;

              case 'conversation.chat.completed':
                break;
            }
          } catch (_) {}
        }
      }

      if (!controller.isClosed) {
        controller.add(const CozeStreamEvent(type: CozeEventType.done));
      }
    } on DioException catch (e) {
      final msg = _extractError(e);
      if (!controller.isClosed) {
        controller.add(CozeStreamEvent(
          type: CozeEventType.error,
          error: msg,
        ));
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.add(CozeStreamEvent(
          type: CozeEventType.error,
          error: '请求失败: $e',
        ));
      }
    } finally {
      if (!controller.isClosed) {
        controller.close();
      }
    }
  }

  Map<String, dynamic>? _buildSensorContext() {
    final dm = DeviceManager.instance;
    final parts = <String>[];
    if (dm.temperature != '--') parts.add('温度${dm.temperature}°C');
    if (dm.humidity != '--') parts.add('空气湿度${dm.humidity}%');
    if (dm.illumination != '--') parts.add('光照强度${dm.illumination}lux');
    parts.add('通风设备:${dm.motorStatus ? "开启" : "关闭"}');
    parts.add('补光设备:${dm.lightStatus ? "开启" : "关闭"}');
    if (parts.length <= 2) return null;
    return {
      'content': '[系统上下文] 当前温室环境数据: ${parts.join("，")}。注意：未列出的传感器表示数据暂未到达，不代表故障，请勿据此判断传感器异常。请基于以上实时数据回答用户问题。',
      'content_type': 'text',
      'role': 'assistant',
      'type': 'answer',
    };
  }

  String _extractError(DioException e) {
    if (e.response?.data != null) {
      try {
        final body = e.response!.data is String
            ? jsonDecode(e.response!.data as String)
            : e.response!.data;
        return body['msg']?.toString() ?? body['message']?.toString() ?? '请求失败';
      } catch (_) {}
    }
    return '网络请求失败: ${e.message}';
  }
}
