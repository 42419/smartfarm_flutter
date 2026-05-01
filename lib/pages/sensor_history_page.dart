import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../config/config.dart';
import '../services/sensor_history_service.dart';

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final Future<Set<DateTime>> availableDatesFuture;

  const _CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.availableDatesFuture,
  });

  @override
  State<_CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
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
        // 如果没有 initialDate 但是有可用日期，默认显示最新的可用月份
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
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    return nextMonth.day;
  }

  int get _firstDayOffset {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    return firstDay.weekday % 7; // Sunday = 0, Monday = 1, ..., Saturday = 6
  }

  int get _minYear {
    if (_availableDates != null && _availableDates!.isNotEmpty) {
      return _availableDates!.map((d) => d.year).reduce((a, b) => a < b ? a : b);
    }
    return 2020;
  }

  int get _maxYear => DateTime.now().year;

  Future<void> _pickYear() async {
    final pickedYear = await showDialog<int>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 200,
            height: 300,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Text('选择年份', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Theme.of(context).colorScheme.primary : null,
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
              children: ['日', '一', '二', '三', '四', '五', '六']
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    : Colors.grey.withValues(alpha: 0.4),
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
                child: const Text('取消', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SensorHistoryPage extends StatefulWidget {
  const SensorHistoryPage({super.key});

  @override
  State<SensorHistoryPage> createState() => _SensorHistoryPageState();
}

class _SensorHistoryPageState extends State<SensorHistoryPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _descending = true;
  int _limit = 100;
  bool _loading = false;
  List<SensorHistoryRecord> _records = const [];
  int _selectedMetricIndex = 0; // 0=温度, 1=湿度, 2=土壤湿度, 3=光照

  final List<Map<String, dynamic>> _metrics = [
    {'label': '温度', 'color': Colors.orangeAccent, 'column': 'temperature'},
    {'label': '湿度', 'color': Colors.blueAccent, 'column': 'humidity'},
    {'label': '土壤湿度', 'color': Colors.green, 'column': 'soil_moisture'},
    {'label': '光照', 'color': Colors.amber, 'column': 'illumination'},
  ];

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _loadRecords(forceRefresh: true);
  }

  Future<void> _loadRecords({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
    });

    final records = await SensorHistoryService.instance.fetchRecords(
      greenhouse: Config.supabaseGreenhouse,
      startDate: _startDate,
      endDate: _endDate,
      descending: _descending,
      limit: _limit,
      forceRefresh: forceRefresh,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final future = SensorHistoryService.instance.fetchAvailableDates(
      greenhouse: Config.supabaseGreenhouse,
    );

    final initialDate = isStart ? _startDate : _endDate;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return _CustomDatePickerDialog(
          initialDate: initialDate,
          availableDatesFuture: future,
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '历史数据查询',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        label: '开始日期',
                        value: _formatDate(_startDate),
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateButton(
                        label: '结束日期',
                        value: _formatDate(_endDate),
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _limit,
                        decoration: _inputDecoration('条数限制'),
                        items: const [50, 100, 200, 500]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('最近$value条'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _limit = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<bool>(
                        value: _descending,
                        decoration: _inputDecoration('排序'),
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
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _descending = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () => _loadRecords(forceRefresh: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B3245),
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
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('当前筛选条件下没有数据',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _records.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildTrendChartSection();
                          }
                          final record = _records[index - 1];
                          return _buildRecordItem(record, index - 1);
                        },
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
        decoration: _inputDecoration(label),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildTrendChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_metrics[_selectedMetricIndex]['label']}趋势图',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_metrics.length, (index) {
                      final isSelected = _selectedMetricIndex == index;
                      final metricColor = _metrics[index]['color'] as Color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMetricIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? metricColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? metricColor.withValues(alpha: 0.3)
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: metricColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _metrics[index]['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? metricColor
                                      : Colors.black54,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildHistoryLineChart(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '详细数据列表',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildRecordItem(SensorHistoryRecord record, int index) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, index == _records.length - 1 ? 16 : 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 5),
                Text(
                  _formatDateTime(record.recordedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                _metricTag(
                  record.temperature,
                  '°C',
                  Colors.orangeAccent,
                ),
                const SizedBox(width: 4),
                _metricTag(
                  record.humidity,
                  '%',
                  Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniChip('光照', record.illumination, 'lux', Colors.amber),
                const SizedBox(width: 8),
                _miniChip('土壤', record.effectiveSoilMoisture, '%', Colors.green),
                const SizedBox(width: 8),
                _miniChip('CO₂', record.co2, 'ppm', Colors.purpleAccent),
                const SizedBox(width: 8),
                _miniChip('pH', record.phValue, '', Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTag(double? value, String unit, Color color) {
    final text = value != null ? '${value.toStringAsFixed(1)}$unit' : '--';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _miniChip(String label, double? value, String unit, Color color) {
    final text = value != null ? '${value.toStringAsFixed(1)}$unit' : '--';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label $text',
          style: TextStyle(fontSize: 11, color: color),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '请选择';
    }
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime value) {
    return '${_formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHistoryLineChart() {
    final lineColor = _metrics[_selectedMetricIndex]['color'] as Color;
    final column = _metrics[_selectedMetricIndex]['column'] as String;

    final reversedRecords = _records.reversed.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < reversedRecords.length; i++) {
      final record = reversedRecords[i];
      double value = 0;

      switch (column) {
        case 'temperature':
          value = record.temperature ?? 0;
          break;
        case 'humidity':
          value = record.humidity ?? 0;
          break;
        case 'soil_moisture':
          value = record.effectiveSoilMoisture;
          break;
        case 'illumination':
          value = record.illumination ?? 0;
          break;
        default:
          value = 0;
      }

      spots.add(FlSpot(i.toDouble(), value));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (spots.length > 1)
                  ? ((spots.length - 1) / 5).ceil().toDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < reversedRecords.length) {
                  final dt = reversedRecords[index].recordedAt;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 20,
              getDotPainter: (spot, xPercentage, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: lineColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withValues(alpha: 0.4),
                  lineColor.withValues(alpha: 0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map(
                    (spot) => LineTooltipItem(
                      spot.y.toStringAsFixed(1),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ),
      ),
    );
  }
}
