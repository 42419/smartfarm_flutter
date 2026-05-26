import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/automation_rule.dart';
import 'app_feedback.dart';
import 'device_manager.dart';

class AutomationService {
  AutomationService._();

  static final AutomationService instance = AutomationService._();

  static const _storageKey = 'automation_rules';
  final List<AutomationRule> _rules = [];
  Timer? _evalTimer;

  List<AutomationRule> get rules => List.unmodifiable(_rules);

  Future<void> loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _rules.clear();
      _rules.addAll(list
          .map((e) => AutomationRule.fromJson(e as Map<String, dynamic>)));
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_rules.map((e) => e.toJson()).toList()),
    );
  }

  void addRule(AutomationRule rule) {
    _rules.add(rule);
    _persist();
  }

  void updateRule(String id, AutomationRule updatedRule) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rules[index] = updatedRule;
      _persist();
    }
  }

  void removeRule(String id) {
    _rules.removeWhere((r) => r.id == id);
    _persist();
  }

  void toggleRule(String id, bool enabled) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rules[index].enabled = enabled;
      _persist();
    }
  }

  void startEngine() {
    _evalTimer?.cancel();
    _evalTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      evaluateAll();
    });
  }

  void stopEngine() {
    _evalTimer?.cancel();
  }

  void evaluateAll() {
    final dm = DeviceManager.instance;
    final now = DateTime.now();

    for (final rule in _rules) {
      if (!rule.enabled) continue;

      if (rule.cooldownMinutes != null && rule.lastTriggeredAt != null) {
        final elapsed = now.difference(rule.lastTriggeredAt!).inMinutes;
        if (elapsed < rule.cooldownMinutes!) continue;
      }

      if (_allConditionsMet(rule.conditions, dm)) {
        _executeActions(rule);
        rule.lastTriggeredAt = now;
        _persist();
      }
    }
  }

  bool _allConditionsMet(
    List<AutomationCondition> conditions,
    DeviceManager dm,
  ) {
    if (conditions.isEmpty) return false;
    for (final cond in conditions) {
      final val = _readMetric(cond.metric, dm);
      if (val == null) return false;
      if (!cond.evaluate(val)) return false;
    }
    return true;
  }

  double? _readMetric(String metric, DeviceManager dm) {
    switch (metric) {
      case 'temperature':
        return double.tryParse(dm.temperature);
      case 'humidity':
        return double.tryParse(dm.humidity);
      case 'illumination':
        return double.tryParse(dm.illumination);
      default:
        return null;
    }
  }

  void _executeActions(AutomationRule rule) {
    for (final action in rule.actions) {
      switch (action.type) {
        case ActionType.deviceControl:
          if (action.commandName != null && action.switchValue != null) {
            DeviceManager.instance.controlDevice(
              action.commandName!,
              action.switchValue!,
            );
            debugPrint(
                '[Automation] 规则"${rule.name}"触发: ${action.commandName} → ${action.switchValue}');
          }
        case ActionType.notification:
          final msg = action.message ?? '自动化规则"${rule.name}"已触发';
          showAppToast(msg);
          debugPrint('[Automation] 通知: $msg');
      }
    }
  }

  void dispose() {
    _evalTimer?.cancel();
  }
}
