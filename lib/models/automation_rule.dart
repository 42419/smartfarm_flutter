enum ConditionOperator { greaterThan, lessThan, equals }

String conditionOpLabel(ConditionOperator op) {
  switch (op) {
    case ConditionOperator.greaterThan:
      return '>';
    case ConditionOperator.lessThan:
      return '<';
    case ConditionOperator.equals:
      return '=';
  }
}

enum ActionType { deviceControl, notification }

String actionTypeLabel(ActionType type) {
  switch (type) {
    case ActionType.deviceControl:
      return '控制设备';
    case ActionType.notification:
      return '推送通知';
  }
}

class AutomationCondition {
  final String metric;
  final ConditionOperator operator;
  final double value;

  const AutomationCondition({
    required this.metric,
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'operator': operator.name,
        'value': value,
      };

  factory AutomationCondition.fromJson(Map<String, dynamic> json) =>
      AutomationCondition(
        metric: json['metric']?.toString() ?? 'temperature',
        operator: ConditionOperator.values.firstWhere(
          (e) => e.name == json['operator'],
          orElse: () => ConditionOperator.greaterThan,
        ),
        value: (json['value'] as num?)?.toDouble() ?? 30,
      );

  bool evaluate(double currentValue) {
    switch (operator) {
      case ConditionOperator.greaterThan:
        return currentValue > value;
      case ConditionOperator.lessThan:
        return currentValue < value;
      case ConditionOperator.equals:
        return currentValue == value;
    }
  }
}

class AutomationAction {
  final ActionType type;
  final String? commandName;
  final String? switchValue;
  final String? message;

  const AutomationAction({
    required this.type,
    this.commandName,
    this.switchValue,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'commandName': commandName,
        'switchValue': switchValue,
        'message': message,
      };

  factory AutomationAction.fromJson(Map<String, dynamic> json) =>
      AutomationAction(
        type: ActionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ActionType.deviceControl,
        ),
        commandName: json['commandName']?.toString(),
        switchValue: json['switchValue']?.toString(),
        message: json['message']?.toString(),
      );
}

class AutomationRule {
  final String id;
  String name;
  bool enabled;
  final List<AutomationCondition> conditions;
  final List<AutomationAction> actions;
  int? cooldownMinutes;
  DateTime? lastTriggeredAt;
  final DateTime createdAt;

  AutomationRule({
    required this.id,
    required this.name,
    this.enabled = true,
    required this.conditions,
    required this.actions,
    this.cooldownMinutes,
    this.lastTriggeredAt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'conditions': conditions.map((e) => e.toJson()).toList(),
        'actions': actions.map((e) => e.toJson()).toList(),
        'cooldownMinutes': cooldownMinutes,
        'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory AutomationRule.fromJson(Map<String, dynamic> json) => AutomationRule(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '新规则',
        enabled: json['enabled'] as bool? ?? true,
        conditions: (json['conditions'] as List<dynamic>?)
                ?.map((e) =>
                    AutomationCondition.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        actions: (json['actions'] as List<dynamic>?)
                ?.map(
                    (e) => AutomationAction.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        cooldownMinutes: json['cooldownMinutes'] as int?,
        lastTriggeredAt:
            DateTime.tryParse(json['lastTriggeredAt']?.toString() ?? ''),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      );

  AutomationRule copyWith({
    String? name,
    bool? enabled,
    List<AutomationCondition>? conditions,
    List<AutomationAction>? actions,
    int? cooldownMinutes,
    DateTime? lastTriggeredAt,
  }) {
    return AutomationRule(
      id: id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      createdAt: createdAt,
    );
  }
}
