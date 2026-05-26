import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/config.dart';
import 'alert_prediction_service.dart';
import 'app_feedback.dart';
import 'mqtt_service.dart';
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
  static const int _dataTimeoutSeconds = 5;
  static final DeviceManager _instance = DeviceManager._internal();
  static DeviceManager get instance => _instance;

  DeviceManager._internal() {
    _init();
  }

  String temperature = '--';
  String humidity = '--';
  String illumination = '--';
  bool motorStatus = false;
  bool lightStatus = false;
  bool pump1Status = false;
  bool pump2Status = false;
  bool silentMode = false;

  bool isDeviceOnline = false;
  bool autoState = false;

  int _lastStatusToastMs = 0;
  static const int _toastCooldownMs = 30000;

  void _showStatusToast(String msg) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastStatusToastMs < _toastCooldownMs) return;
    _lastStatusToastMs = now;
    // showAppToast(msg);
  }

  final Map<String, _PendingDeviceCommand> _pendingCommands = {};
  final Map<String, Timer> _pendingCommandTimers = {};
  Timer? _dataWatchdog;
  Timer? _predictionTimer;
  StreamSubscription<Map<String, dynamic>>? _reportSub;
  StreamSubscription<Map<String, dynamic>>? _statusSub;

  Future<void> _init() async {
    await MqttService.instance.connect();
    _reportSub = MqttService.instance.reportStream.listen(_onReportMessage);
    _statusSub = MqttService.instance.statusStream.listen(_onStatusMessage);
    _startPredictionLoop();
  }

  void _startPredictionLoop() {
    _predictionTimer?.cancel();
    _predictionTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _runPredictionAnalysis();
    });
    _runPredictionAnalysis();
  }

  Future<void> _runPredictionAnalysis() async {
    try {
      final points = await SensorHistoryService.instance.fetchRecentPoints(
        greenhouse: Config.supabaseGreenhouse,
        hours: 12,
      );
      if (points.isEmpty) return;

      final newAlerts = await AlertPredictionService.instance.analyzeAndPredict(points);
      for (final alert in newAlerts) {
        AlertPredictionService.instance.addAlert(alert);
      }
    } catch (_) {}
  }

  void toggleAllIrrigation(bool on) {
    pump1Status = on;
    pump2Status = on;
    notifyListeners();
  }

  Future<void> controlDevice(String commandName, String switchName) async {
    try {
      final bool expectedStatus = switchName == 'ON';
      final int nowMs = DateTime.now().millisecondsSinceEpoch;

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

      MqttService.instance.sendCommand(commandName, switchName);
      debugPrint('DeviceManager: MQTT command sent - $commandName → $switchName');
    } catch (e) {
      _failPendingCommand(commandName, revertOptimisticState: true);
      debugPrint('DeviceManager: Error sending command: $e');
    }
  }

  void _onReportMessage(Map<String, dynamic> data) {
    int messageTimestampMs = DateTime.now().millisecondsSinceEpoch;

    _dataWatchdog?.cancel();
    if (!isDeviceOnline) {
      isDeviceOnline = true;
      if (!silentMode) _showStatusToast('设备已上线');
      notifyListeners();
    }
    _dataWatchdog = Timer(const Duration(seconds: _dataTimeoutSeconds), () {
      if (isDeviceOnline) {
        isDeviceOnline = false;
        if (!silentMode) _showStatusToast('设备已离线');
        notifyListeners();
      }
    });

    if (data['motorStatus'] != null) {
      _applyIncomingDeviceStatus(
        commandName: 'motor_control',
        nextStatus: data['motorStatus'] == 'ON',
        messageTimestampMs: messageTimestampMs,
        onAccept: (value) => motorStatus = value,
      );
    }
    if (data['lightStatus'] != null) {
      _applyIncomingDeviceStatus(
        commandName: 'light_control',
        nextStatus: data['lightStatus'] == 'ON',
        messageTimestampMs: messageTimestampMs,
        onAccept: (value) => lightStatus = value,
      );
    }
    if (data['temperature'] != null) {
      temperature =
          data['temperature'].toString().replaceAll('℃', '').trim();
    }
    if (data['humidity'] != null) {
      humidity =
          data['humidity'].toString().replaceAll('%', '').trim();
    }
    if (data['illumination'] != null) {
      illumination = data['illumination']
          .toString()
          .replaceAll(RegExp(r'[L|l]ux'), '')
          .trim();
    }
    if (data['autoStatus'] != null) {
      autoState = data['autoStatus'] == 'ON';
    }

    unawaited(
      SensorHistoryService.instance.recordReading(
        greenhouse: Config.supabaseGreenhouse,
        temperature: _parseNumericValue(data['temperature']),
        humidity: _parseNumericValue(data['humidity']),
        illumination: _parseNumericValue(data['illumination']),
        soilMoisture: _parseNumericValue(data['soilMoisture']),
        co2: _parseNumericValue(data['co2']),
        phValue: _parseNumericValue(data['ph']),
      ),
    );

    notifyListeners();
  }

  void _onStatusMessage(Map<String, dynamic> data) {
    if (data['status'] != null) {
      final wasOnline = isDeviceOnline;
      isDeviceOnline = data['status'] == 'online';
      if (data['status'] == 'online') {
        _dataWatchdog?.cancel();
        _dataWatchdog = Timer(
          const Duration(seconds: _dataTimeoutSeconds),
          () {
              if (isDeviceOnline) {
                isDeviceOnline = false;
                if (!silentMode) _showStatusToast('设备已离线');
                notifyListeners();
              }
            },
          );
        } else {
          _dataWatchdog?.cancel();
        }
        if (wasOnline != isDeviceOnline) {
          if (!silentMode) {
            _showStatusToast(
              isDeviceOnline ? '设备已上线' : '设备已离线',
            );
        }
        notifyListeners();
      }
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

    if (messageTimestampMs <= pending.commandIssuedAtMs) {
      return;
    }

    if (nextStatus == pending.expectedStatus) {
      onAccept(nextStatus);
      _clearPendingCommand(commandName);
      // if (!silentMode) showAppToast('${pending.deviceLabel}操作成功');
      return;
    }

    if (DateTime.now().millisecondsSinceEpoch <= pending.protectUntilMs) {
      return;
    }

    onAccept(nextStatus);
    _clearPendingCommand(commandName);
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

  @override
  void dispose() {
    _dataWatchdog?.cancel();
    _predictionTimer?.cancel();
    _reportSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
