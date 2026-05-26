import 'package:flutter/material.dart';

class QueryForm extends StatelessWidget {
  const QueryForm({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.limit,
    required this.descending,
    required this.loading,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onLimitChanged,
    required this.onDescendingChanged,
    required this.onQuery,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final bool descending;
  final bool loading;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final ValueChanged<int?> onLimitChanged;
  final ValueChanged<bool?> onDescendingChanged;
  final VoidCallback onQuery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateButton(context,
                  label: '开始日期',
                  value: _formatDate(startDate),
                  onTap: onPickStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(context,
                  label: '结束日期',
                  value: _formatDate(endDate),
                  onTap: onPickEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSelectChip<int>(
                  context,
                  value: limit,
                  items: const [50, 100, 200, 500],
                  labelBuilder: (value) => '最近$value条',
                  onChanged: onLimitChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectChip<bool>(
                  context,
                  value: descending,
                  items: const [true, false],
                  labelBuilder: (value) => value ? '最新在前' : '最早在前',
                  onChanged: onDescendingChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: loading ? null : onQuery,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('查询'),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration(ColorScheme cs, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildSelectChip<T>(
    BuildContext context, {
    required T value,
    required List<T> items,
    required String Function(T value) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: cs.onSurfaceVariant,
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          dropdownColor: cs.surface,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(cs, label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: TextStyle(color: cs.onSurface)),
            Icon(Icons.calendar_month_outlined, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '请选择';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
