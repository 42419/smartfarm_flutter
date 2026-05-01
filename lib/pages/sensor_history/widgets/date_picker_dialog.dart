import 'package:flutter/material.dart';

class CustomDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final Future<Set<DateTime>> availableDatesFuture;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.availableDatesFuture,
  });

  @override
  State<CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime _currentMonth;
  Set<DateTime>? _availableDates;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      widget.initialDate?.year ?? DateTime.now().year,
      widget.initialDate?.month ?? DateTime.now().month,
    );
    _loadDates();
  }

  Future<void> _loadDates() async {
    final dates = await widget.availableDatesFuture;
    if (mounted) {
      setState(() {
        _availableDates = dates;
        if (widget.initialDate == null && dates.isNotEmpty) {
          final latestDate = dates.reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );
          _currentMonth = DateTime(latestDate.year, latestDate.month);
        }
      });
    }
  }

  int get _daysInMonth {
    final nextMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    return nextMonth.day;
  }

  int get _firstDayOffset {
    final firstDay =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    return firstDay.weekday % 7;
  }

  int get _minYear {
    if (_availableDates != null && _availableDates!.isNotEmpty) {
      return _availableDates!
          .map((d) => d.year)
          .reduce((a, b) => a < b ? a : b);
    }
    return 2020;
  }

  int get _maxYear => DateTime.now().year;

  Future<void> _pickYear() async {
    final pickedYear = await showDialog<int>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 200,
            height: 300,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Text('选择年份',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _maxYear - _minYear + 1,
                    itemBuilder: (context, index) {
                      final year = _maxYear - index;
                      final isCurrent = year == _currentMonth.year;
                      return ListTile(
                        dense: true,
                        title: Text(
                          '$year 年',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(year),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (pickedYear != null && mounted) {
      setState(() {
        _currentMonth = DateTime(pickedYear, _currentMonth.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                      );
                    });
                  },
                ),
                GestureDetector(
                  onTap: () => _pickYear(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_currentMonth.year}年 ${_currentMonth.month}月',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                '日',
                '一',
                '二',
                '三',
                '四',
                '五',
                '六'
              ]
                  .map(
                    (e) => Text(
                      e,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            _availableDates == null
                ? const SizedBox(
                    height: 252,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox(
                    height: 252,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: _daysInMonth + _firstDayOffset,
                      itemBuilder: (context, index) {
                        if (index < _firstDayOffset) {
                          return const SizedBox();
                        }
                        final day = index - _firstDayOffset + 1;
                        final date = DateTime(
                          _currentMonth.year,
                          _currentMonth.month,
                          day,
                        );
                        final isAvailable = _availableDates!.contains(date);
                        final isSelected = widget.initialDate != null &&
                            date.year == widget.initialDate!.year &&
                            date.month == widget.initialDate!.month &&
                            date.day == widget.initialDate!.day;

                        return GestureDetector(
                          onTap: isAvailable
                              ? () {
                                  Navigator.of(context).pop(date);
                                }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2B3245)
                                  : isAvailable
                                      ? const Color(0xFFF3F6FA)
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : isAvailable
                                        ? Colors.black87
                                        : Colors.grey
                                            .withValues(alpha: 0.4),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
