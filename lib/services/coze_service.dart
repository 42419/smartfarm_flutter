import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/config.dart';
import 'crop_service.dart';
import 'device_manager.dart';
import 'weather_service.dart';

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
    final ws = WeatherService.instance;
    final parts = <String>[];
    if (dm.temperature != '--') parts.add('温度${dm.temperature}°C');
    if (dm.humidity != '--') parts.add('空气湿度${dm.humidity}%');
    if (dm.illumination != '--') parts.add('光照强度${dm.illumination}lux');
    parts.add('通风设备:${dm.motorStatus ? "开启" : "关闭"}');
    parts.add('补光设备:${dm.lightStatus ? "开启" : "关闭"}');
    parts.add('灌溉泵1:${dm.pump1Status ? "开启" : "关闭"}');
    parts.add('灌溉泵2:${dm.pump2Status ? "开启" : "关闭"}');

    if (ws.fetched) {
      parts.add('室外天气:${ws.weatherText} ${ws.weatherTemp}');
      parts.add('室外风力:${ws.weatherWind}');
      parts.add('室外湿度:${ws.weatherHumidity}');
    }

    if (parts.length <= 2) return null;

    final cropCtx = _buildCropContext();

    return {
      'content': [
        '[系统上下文] 当前温室环境数据: ${parts.join("，")}。',
        if (cropCtx != null) cropCtx,
        '注意：未列出的传感器表示数据暂未到达，不代表故障，请勿据此判断传感器异常。',
        '你是智慧农业AI助手，可提供专业灌溉建议、施肥方案、病虫害防治建议。',
        '当用户询问灌溉、施肥、病虫害等问题时，请结合实时环境数据、室外天气和作物信息给出量化建议（如具体灌溉量、施肥比例、药剂浓度等）。',
        '如果数据不足以给出精确建议，请主动指出并给出合理推测加上"建议实地确认"的提醒。',
      ].where((s) => s.isNotEmpty).join('\n'),
      'content_type': 'text',
      'role': 'assistant',
      'type': 'answer',
    };
  }

  static String? _buildCropContext() {
    final crops = CropService.instance.cachedCrops;
    if (crops.isEmpty) return null;
    final sb = StringBuffer();
    sb.write('大棚作物信息: ');
    for (var i = 0; i < crops.length && i < 5; i++) {
      final c = crops[i];
      sb.write('${i + 1}号大棚-${c.cropName}');
      if (c.health != null) sb.write('(${c.health})');
      if (c.plantDate != null) sb.write('[定植:${c.plantDate}]');
      if (i < crops.length - 1 && i < 4) sb.write('; ');
    }
    return sb.toString();
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
