import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config.dart';

class MqttService {
  static final MqttService instance = MqttService._internal();

  MqttService._internal();

  MqttServerClient? _client;
  bool _isConnected = false;
  String? _clientId;

  final _reportController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get reportStream => _reportController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  bool get isConnected => _isConnected;

  bool _connecting = false;

  Future<void> connect() async {
    if (_isConnected || _connecting) return;
    _connecting = true;

    _clientId = await _getOrCreateClientId();

    _client = MqttServerClient.withPort(
      Config.emqxHost,
      _clientId!,
      Config.emqxPort,
    );

    _client!.logging(on: false);
    _client!.keepAlivePeriod = 30;
    _client!.autoReconnect = true;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onAutoReconnect = _onAutoReconnect;
    _client!.onAutoReconnected = _onAutoReconnected;
    _client!.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withWillTopic(Config.topicStatus)
        .withWillMessage('{"status":"offline"}')
        .withWillQos(MqttQos.atLeastOnce)
        .withWillRetain()
        .startClean();

    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      debugPrint('MqttService: Connection error $e');
      _connecting = false;
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    debugPrint('MqttService: Connected to EMQX');
    _isConnected = true;
    _connecting = false;
    _subscribe();
    _publishOnline();
  }

  void _onDisconnected() {
    debugPrint('MqttService: Disconnected from EMQX');
    _isConnected = false;
    _connecting = false;
  }

  void _onAutoReconnect() {
    debugPrint('MqttService: Auto-reconnecting...');
    _isConnected = false;
  }

  void _onAutoReconnected() {
    debugPrint('MqttService: Auto-reconnected to EMQX');
    _isConnected = true;
    _subscribe();
    _publishOnline();
  }

  void _onSubscribed(String topic) {
    debugPrint('MqttService: Subscribed to $topic');
  }

  void _scheduleReconnect() {
    Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  void _subscribe() {
    if (_client == null || !_isConnected) return;

    _client!.subscribe(Config.topicReport, MqttQos.atLeastOnce);
    _client!.subscribe(Config.topicStatus, MqttQos.atLeastOnce);

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0];
      final topic = recMess.topic;
      final publishMsg = recMess.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        publishMsg.payload.message,
      );

      try {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        if (topic == Config.topicReport) {
          _reportController.add(json);
        } else if (topic == Config.topicStatus) {
          _statusController.add(json);
        }
      } catch (e) {
        debugPrint('MqttService: Failed to parse message from $topic: $e');
      }
    });
  }

  void _publishOnline() {
    publish(Config.topicStatus, '{"status":"online"}', retain: true);
  }

  void publish(String topic, String message, {bool retain = false}) {
    if (_client == null || !_isConnected) {
      debugPrint('MqttService: Cannot publish, not connected');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: retain,
    );
  }

  void sendCommand(String commandName, String switchValue) {
    final payload = jsonEncode({
      'command_name': commandName,
      'paras': {'switch': switchValue},
    });
    publish(Config.topicCommand, payload);
  }

  Future<String> _getOrCreateClientId() async {
    const key = 'mqtt_client_uuid';
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(key);
    if (id == null || id.isEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final random = (Random().nextInt(99999)).toString().padLeft(5, '0');
      id = 'sf_${timestamp}_$random';
      await prefs.setString(key, id);
    }
    debugPrint('MqttService: Using client ID $id');
    return id;
  }

  void disconnect() {
    if (_client != null && _isConnected) {
      publish(Config.topicStatus, '{"status":"offline"}', retain: true);
    }
    _client?.disconnect();
    _isConnected = false;
    _connecting = false;
  }

  void dispose() {
    disconnect();
    _reportController.close();
    _statusController.close();
  }
}
