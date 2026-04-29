import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/config.dart';
import 'app_feedback.dart';
import 'sensor_history_service.dart';

class _PendingDeviceCommand {
  _PendingDeviceCommand({
    required this.commandName,
    required this.expectedStatus,
    required this.commandIssuedAtMs,
    required this.protectUntilMs,
    required this.deviceLabel,
  });

  final String commandName;
  final bool expectedStatus;
  final int commandIssuedAtMs;
  final int protectUntilMs;
  final String deviceLabel;
}

class DeviceManager extends ChangeNotifier {
  static const int _commandProtectWindowMs = 5000;
  static final DeviceManager _instance = DeviceManager._internal();
  static DeviceManager get instance => _instance;

  DeviceManager._internal() {
    _init();
  }

  final Dio _dio = Dio();
  String _token = '';
  WebSocketChannel? _channel;

  // 全局共享的设备状态数据
  String temperature = '--';
  String humidity = '--';
  String illumination = '--';
  bool motorStatus = false; // 通风设备#001
  bool lightStatus = false; // 补光设备#001
  final Map<String, _PendingDeviceCommand> _pendingCommands = {};
  final Map<String, Timer> _pendingCommandTimers = {};

  Future<void> _init() async {
    await _getToken();
    _connectWebSocket();
  }

  // 1. 获取Token
  Future<void> _getToken() async {
    try {
      var response = await _dio.post(
          Config.iamAuthUrl,
          data: {
            "auth": {
              "identity": {
                "methods": ["password"],
                "password": {
                  "user": {
                    "name": Config.iamUser,
                    "password": Config.iamPassword,
                    "domain": {
                      "name": Config.iamDomain
                    }
                  }
                }
              },
              "scope": {
                "project": {
                  "name": Config.iamProject
                }
              }
            }
          }
      );
      _token = response.headers.value('x-subject-token') ?? '';
      debugPrint('DeviceManager: Token fetched successfully');
    } catch (e) {
      debugPrint('DeviceManager Error fetching token: $e');
    }
  }

  // 2. 控制硬件设备
  Future<void> controlDevice(String commandName, String switchName) async {
    if (_token.isEmpty) {
      await _getToken();
    }

    try {
      final bool expectedStatus = switchName == 'ON';
      final int nowMs = DateTime.now().millisecondsSinceEpoch;

      // 乐观更新UI，先在本地改变状态让开关立刻产生反应
      if (commandName == 'motor_control') {
        motorStatus = expectedStatus;
      } else if (commandName == 'light_control') {
        lightStatus = expectedStatus;
      }

      _setPendingCommand(
        commandName: commandName,
        expectedStatus: expectedStatus,
        commandIssuedAtMs: nowMs,
      );
      notifyListeners();

      var response = await _dio.post(
          Config.iotCommandUrl,
          options: Options(
              headers: {
                'Content-Type': 'application/json',
                'X-Auth-Token': _token,
                'Instance-Id': Config.iotInstanceId,
              }
          ),
          data: {
            "service_id": Config.iotServiceId,
            "command_name": commandName,
            "paras": {
              "switch": switchName
            }
          }
      );
      debugPrint('DeviceManager: Command sent - ${response.data}');
    } catch (e) {
      _failPendingCommand(commandName, revertOptimisticState: true);
      debugPrint('DeviceManager: Error controlling device: $e');
    }
  }

  // 3. 连接WebSocket实时获取数据
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(Config.webSocketUrl),
      );
      _channel!.stream.listen((message) {
        if (message is String) {
          try {
            var decoded = jsonDecode(message);
            dynamic props;
            int messageTimestampMs = DateTime.now().millisecondsSinceEpoch;
            if (decoded is List && decoded.isNotEmpty) {
              props = decoded[0]['properties'];
            } else if (decoded is Map && decoded['data'] != null && decoded['data'].isNotEmpty) {
              props = decoded['data'][0]['properties'];
              final dynamic rawTimestamp = decoded['timestamp'];
              if (rawTimestamp is int) {
                messageTimestampMs = rawTimestamp;
              } else if (rawTimestamp is String) {
                messageTimestampMs = int.tryParse(rawTimestamp) ?? messageTimestampMs;
              }
            }

            if (props != null) {
              // 更新解析数据
              if (props['motorStatus'] != null) {
                _applyIncomingDeviceStatus(
                  commandName: 'motor_control',
                  nextStatus: props['motorStatus'] == 'ON',
                  messageTimestampMs: messageTimestampMs,
                  onAccept: (value) => motorStatus = value,
                );
              }
              if (props['lightStatus'] != null) {
                _applyIncomingDeviceStatus(
                  commandName: 'light_control',
                  nextStatus: props['lightStatus'] == 'ON',
                  messageTimestampMs: messageTimestampMs,
                  onAccept: (value) => lightStatus = value,
                );
              }
              if (props['temperature'] != null) {
                temperature = props['temperature'].toString().replaceAll('℃', '').trim();
              }
              if (props['humidity'] != null) {
                humidity = props['humidity'].toString().replaceAll('%', '').trim();
              }
              if (props['illumination'] != null) {
                // 忽略大小写去掉 Lux
                illumination = props['illumination'].toString().replaceAll(RegExp(r'[L|l]ux'), '').trim();
              }
              unawaited(
                SensorHistoryService.instance.recordReading(
                  greenhouse: Config.supabaseGreenhouse,
                  temperature: _parseNumericValue(props['temperature']),
                  humidity: _parseNumericValue(props['humidity']),
                  illumination: _parseNumericValue(props['illumination']),
                  soilMoisture: _parseNumericValue(props['soilMoisture']),
                  co2: _parseNumericValue(props['co2']),
                  phValue: _parseNumericValue(props['ph']),
                ),
              );
              // 数据获取成功后，通知所有页面通过addListener响应和刷新UI
              notifyListeners();
            }
          } catch (e) {
            // 解析失败不阻断服务
          }
        }
      }, onError: (error) {
        debugPrint("DeviceManager: WebSocket Stream Error: $error");
      });
    } catch (e) {
      debugPrint("DeviceManager: WebSocket Connection Error: $e");
    }
  }

  void _setPendingCommand({
    required String commandName,
    required bool expectedStatus,
    required int commandIssuedAtMs,
  }) {
    _pendingCommandTimers.remove(commandName)?.cancel();
    _pendingCommands[commandName] = _PendingDeviceCommand(
      commandName: commandName,
      expectedStatus: expectedStatus,
      commandIssuedAtMs: commandIssuedAtMs,
      protectUntilMs: commandIssuedAtMs + _commandProtectWindowMs,
      deviceLabel: _deviceLabel(commandName),
    );
    _pendingCommandTimers[commandName] = Timer(
      const Duration(milliseconds: _commandProtectWindowMs),
      () {
        _failPendingCommand(commandName, revertOptimisticState: true);
      },
    );
  }

  void _applyIncomingDeviceStatus({
    required String commandName,
    required bool nextStatus,
    required int messageTimestampMs,
    required void Function(bool value) onAccept,
  }) {
    final pending = _pendingCommands[commandName];
    if (pending == null) {
      onAccept(nextStatus);
      return;
    }

    // 忽略命令发起前或保护窗口内回放的旧状态，避免把乐观更新刷回去。
    if (messageTimestampMs <= pending.commandIssuedAtMs &&
        messageTimestampMs <= pending.protectUntilMs) {
      return;
    }

    if (nextStatus == pending.expectedStatus) {
      onAccept(nextStatus);
      _clearPendingCommand(commandName);
      showAppToast('${pending.deviceLabel}操作成功');
      return;
    }

    onAccept(nextStatus);
    _clearPendingCommand(commandName);
    showAppToast('${pending.deviceLabel}操作失败');
  }

  void _failPendingCommand(
    String commandName, {
    required bool revertOptimisticState,
  }) {
    final pending = _pendingCommands[commandName];
    if (pending == null) {
      return;
    }

    if (revertOptimisticState) {
      if (commandName == 'motor_control') {
        motorStatus = !pending.expectedStatus;
      } else if (commandName == 'light_control') {
        lightStatus = !pending.expectedStatus;
      }
      notifyListeners();
    }

    _clearPendingCommand(commandName);
    showAppToast('${pending.deviceLabel}操作失败');
  }

  void _clearPendingCommand(String commandName) {
    _pendingCommandTimers.remove(commandName)?.cancel();
    _pendingCommands.remove(commandName);
  }

  String _deviceLabel(String commandName) {
    switch (commandName) {
      case 'motor_control':
        return '通风设备';
      case 'light_control':
        return '补光设备';
      default:
        return '设备';
    }
  }

  double? _parseNumericValue(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      return raw.toDouble();
    }

    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(raw.toString());
    return match == null ? null : double.tryParse(match.group(0)!);
  }
}
