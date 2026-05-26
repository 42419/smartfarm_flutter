import 'package:flutter/material.dart';

import '../../models/automation_rule.dart';
import '../../services/automation_service.dart';

class AutomationPage extends StatefulWidget {
  const AutomationPage({super.key});

  @override
  State<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutomationPage> {
  List<AutomationRule> get _rules => AutomationService.instance.rules;

  @override
  void initState() {
    super.initState();
    AutomationService.instance.loadRules();
  }

  void _refresh() {
    setState(() {});
  }

  void _openEdit({AutomationRule? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _RuleEditPage(existing: existing, onSaved: _refresh),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('自动化规则'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(),
        child: const Icon(Icons.add),
      ),
      body: _rules.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_fix_high,
                      size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('暂无自动化规则',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('点击右下角 + 创建规则',
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rules.length,
              itemBuilder: (context, index) {
                final rule = _rules[index];
                return _RuleCard(
                  rule: rule,
                  onToggle: (v) {
                    AutomationService.instance.toggleRule(rule.id, v);
                    _refresh();
                  },
                  onEdit: () => _openEdit(existing: rule),
                  onDelete: () {
                    AutomationService.instance.removeRule(rule.id);
                    _refresh();
                  },
                );
              },
            ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final AutomationRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _conditionSummary() {
    final parts = rule.conditions.map((c) {
      return '${_metricLabel(c.metric)} ${conditionOpLabel(c.operator)} ${c.value}';
    });
    return parts.join(' 且 ');
  }

  String _actionSummary() {
    final parts = rule.actions.map((a) {
      if (a.type == ActionType.deviceControl) {
        return '${_deviceLabel(a.commandName ?? '')} ${a.switchValue == 'ON' ? '开' : '关'}';
      }
      return a.message ?? '通知';
    });
    return parts.join('，');
  }

  String _metricLabel(String m) {
    switch (m) {
      case 'temperature':
        return '温度';
      case 'humidity':
        return '湿度';
      case 'illumination':
        return '光照';
      default:
        return m;
    }
  }

  String _deviceLabel(String cmd) {
    switch (cmd) {
      case 'motor_control':
        return '通风';
      case 'light_control':
        return '补光';
      default:
        return cmd;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: rule.enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.bolt, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '当 $_conditionSummary()',
                    style: TextStyle(
                        fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.play_arrow, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '则 $_actionSummary()',
                    style: TextStyle(
                        fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('编辑', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  icon:
                      Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  label: Text('删除',
                      style:
                          TextStyle(fontSize: 13, color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleEditPage extends StatefulWidget {
  const _RuleEditPage({this.existing, required this.onSaved});

  final AutomationRule? existing;
  final VoidCallback onSaved;

  @override
  State<_RuleEditPage> createState() => _RuleEditPageState();
}

class _RuleEditPageState extends State<_RuleEditPage> {
  late final TextEditingController _nameCtrl;
  late List<_ConditionData> _conditions;
  late List<_ActionData> _actions;
  int? _cooldown;
  bool _enabled = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _enabled = existing?.enabled ?? true;
    _cooldown = existing?.cooldownMinutes;
    _conditions = existing?.conditions.map((c) => _ConditionData.fromModel(c)).toList() ??
        [_ConditionData()];
    _actions = existing?.actions.map((a) => _ActionData.fromModel(a)).toList() ??
        [_ActionData()];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入规则名称')),
      );
      return;
    }

    final rule = AutomationRule(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      enabled: _enabled,
      conditions:
          _conditions.map((c) => c.toModel()).toList(),
      actions:
          _actions.map((a) => a.toModel()).toList(),
      cooldownMinutes: _cooldown,
      lastTriggeredAt: widget.existing?.lastTriggeredAt,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      AutomationService.instance.updateRule(rule.id, rule);
    } else {
      AutomationService.instance.addRule(rule);
    }
    widget.onSaved();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑规则' : '新建规则'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('规则名称', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: '如：夜间保温规则',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('启用', style: TextStyle(fontSize: 14)),
                Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('触发条件（全部满足）',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _conditions.add(_ConditionData())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                ),
              ],
            ),
            ..._conditions.asMap().entries.map((entry) {
              return _buildConditionRow(entry.key, entry.value);
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('执行动作',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _actions.add(_ActionData())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                ),
              ],
            ),
            ..._actions.asMap().entries.map((entry) {
              return _buildActionRow(entry.key, entry.value);
            }),
            const SizedBox(height: 16),
            const Text('冷却时间（分钟，防止重复触发）',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: _cooldown?.toString() ?? '',
                      ),
                      decoration: InputDecoration(
                        hintText: '如 30',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onChanged: (v) =>
                          _cooldown = int.tryParse(v),
                    ),
                  ),
                const SizedBox(width: 12),
                const Text('分钟',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionRow(int index, _ConditionData data) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _metricDropdown(data),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ConditionOperator>(
                        value: data.op,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(10),
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: cs.onSurfaceVariant),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface),
                        dropdownColor: cs.surface,
                        items: ConditionOperator.values.map((op) {
                          return DropdownMenuItem(
                            value: op,
                            child: Text(conditionOpLabel(op)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => data.op = v);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlignVertical: TextAlignVertical.center,
                      controller: TextEditingController(
                          text: data.value.toString()),
                      decoration: InputDecoration(
                        suffixText: _unitSuffix(data.metric),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                      ),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface),
                      onChanged: (v) =>
                          data.value = double.tryParse(v) ?? data.value,
                    ),
                  ),
                ),
                if (_conditions.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent, size: 22),
                      onPressed: () =>
                          setState(() => _conditions.removeAt(index)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(int index, _ActionData data) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ActionType>(
                        value: data.type,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(10),
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: cs.onSurfaceVariant),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface),
                        dropdownColor: cs.surface,
                        items: ActionType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(actionTypeLabel(t),
                                style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => data.type = v);
                        },
                      ),
                    ),
                  ),
                ),
                if (_actions.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent, size: 22),
                      onPressed: () =>
                          setState(() => _actions.removeAt(index)),
                    ),
                  ),
              ],
            ),
            if (data.type == ActionType.deviceControl) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: data.commandName,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(10),
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: cs.onSurfaceVariant),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface),
                          dropdownColor: cs.surface,
                          items: const [
                            DropdownMenuItem(
                                value: 'motor_control',
                                child: Text('通风',
                                    style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(
                                value: 'light_control',
                                child: Text('补光',
                                    style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (v) {
                            if (v != null)
                              setState(() => data.commandName = v);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: data.switchValue,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(10),
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: cs.onSurfaceVariant),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface),
                          dropdownColor: cs.surface,
                          items: const [
                            DropdownMenuItem(
                                value: 'ON',
                                child: Text('开',
                                    style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(
                                value: 'OFF',
                                child: Text('关',
                                    style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (v) {
                            if (v != null)
                              setState(() => data.switchValue = v);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (data.type == ActionType.notification) ...[
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: data.message),
                decoration: InputDecoration(
                  hintText: '通知内容',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                ),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface),
                onChanged: (v) => data.message = v,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricDropdown(_ConditionData data) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: data.metric,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: cs.onSurfaceVariant),
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface),
          dropdownColor: cs.surface,
          items: const [
            DropdownMenuItem(
                value: 'temperature',
                child: Text('温度', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(
                value: 'humidity',
                child: Text('湿度', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(
                value: 'illumination',
                child: Text('光照', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (v) {
            if (v != null) setState(() => data.metric = v);
          },
        ),
      ),
    );
  }

  String _unitSuffix(String metric) {
    switch (metric) {
      case 'temperature':
        return '°C';
      case 'humidity':
        return '%';
      case 'illumination':
        return 'lux';
      default:
        return '';
    }
  }
}

class _ConditionData {
  String metric;
  ConditionOperator op;
  double value;

  _ConditionData({
    this.metric = 'temperature',
    this.op = ConditionOperator.greaterThan,
    this.value = 30,
  });

  _ConditionData.fromModel(AutomationCondition c)
      : metric = c.metric,
        op = c.operator,
        value = c.value;

  AutomationCondition toModel() => AutomationCondition(
        metric: metric,
        operator: op,
        value: value,
      );
}

class _ActionData {
  ActionType type;
  String? commandName;
  String? switchValue;
  String? message;

  _ActionData({
    this.type = ActionType.deviceControl,
    this.commandName = 'motor_control',
    this.switchValue = 'ON',
    this.message,
  });

  _ActionData.fromModel(AutomationAction a)
      : type = a.type,
        commandName = a.commandName,
        switchValue = a.switchValue,
        message = a.message;

  AutomationAction toModel() => AutomationAction(
        type: type,
        commandName: commandName,
        switchValue: switchValue,
        message: message,
      );
}
