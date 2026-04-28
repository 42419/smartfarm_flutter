import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/config.dart';

class DeviceManager extends ChangeNotifier {
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
      // 乐观更新UI，先在本地改变状态让开关立刻产生反应
      if (commandName == 'motor_control') {
        motorStatus = switchName == 'ON';
      } else if (commandName == 'light_control') {
        lightStatus = switchName == 'ON';
      }
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
            if (decoded is List && decoded.isNotEmpty) {
              props = decoded[0]['properties'];
            } else if (decoded is Map && decoded['data'] != null && decoded['data'].isNotEmpty) {
              props = decoded['data'][0]['properties'];
            }

            if (props != null) {
              // 更新解析数据
              if (props['motorStatus'] != null) {
                motorStatus = props['motorStatus'] == 'ON';
              }
              if (props['lightStatus'] != null) {
                lightStatus = props['lightStatus'] == 'ON';
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
}
