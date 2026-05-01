import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: '开始日期',
                  value: _formatDate(startDate),
                  onTap: onPickStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
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
                child: DropdownButtonFormField<int>(
                  initialValue: limit,
                  decoration: AppDecorations.inputDecoration('条数限制'),
                  items: const [50, 100, 200, 500]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('最近$value条'),
                        ),
                      )
                      .toList(),
                  onChanged: onLimitChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  initialValue: descending,
                  decoration: AppDecorations.inputDecoration('排序'),
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('最新在前'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('最早在前'),
                    ),
                  ],
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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

  Widget _buildDateButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: AppDecorations.inputDecoration(label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value),
            const Icon(Icons.calendar_month_outlined, size: 18),
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
