import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../models/sensor_history_record.dart';
import '../../services/sensor_history_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/metric_selector.dart';
import 'widgets/date_picker_dialog.dart';
import 'widgets/query_form.dart';
import 'widgets/record_item.dart';
import 'widgets/trend_chart_section.dart';

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
  int _selectedMetricIndex = 0;

  final List<MetricOption> _metrics = const [
    MetricOption(label: '温度', color: Colors.orangeAccent, column: 'temperature'),
    MetricOption(label: '湿度', color: Colors.blueAccent, column: 'humidity'),
    MetricOption(label: '土壤湿度', color: Colors.green, column: 'soil_moisture'),
    MetricOption(label: '光照', color: Colors.amber, column: 'illumination'),
  ];

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _loadRecords(forceRefresh: true);
  }

  Future<void> _loadRecords({bool forceRefresh = false}) async {
    setState(() => _loading = true);

    final records = await SensorHistoryService.instance.fetchRecords(
      greenhouse: Config.supabaseGreenhouse,
      startDate: _startDate,
      endDate: _endDate,
      descending: _descending,
      limit: _limit,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

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
        return CustomDatePickerDialog(
          initialDate: initialDate,
          availableDatesFuture: future,
        );
      },
    );

    if (picked == null) return;

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '历史数据查询',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Builder(
        builder: (context) {
          final isDesktop = Responsive.isDesktop(context);
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('当前筛选条件下没有数据',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
            );
          }

          if (isDesktop) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildDesktopBody(context),
            );
          }

          return Column(
            children: [
              QueryForm(
                startDate: _startDate,
                endDate: _endDate,
                limit: _limit,
                descending: _descending,
                loading: _loading,
                onPickStartDate: () => _pickDate(isStart: true),
                onPickEndDate: () => _pickDate(isStart: false),
                onLimitChanged: (value) {
                  if (value != null) setState(() => _limit = value);
                },
                onDescendingChanged: (value) {
                  if (value != null) setState(() => _descending = value);
                },
                onQuery: () => _loadRecords(forceRefresh: true),
              ),
              Expanded(child: _buildRecordList(context)),
            ],
          );
          },
      ),
    );
  }

  Widget _buildDesktopBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QueryForm(
          startDate: _startDate,
          endDate: _endDate,
          limit: _limit,
          descending: _descending,
          loading: _loading,
          onPickStartDate: () => _pickDate(isStart: true),
          onPickEndDate: () => _pickDate(isStart: false),
          onLimitChanged: (value) {
            if (value != null) setState(() => _limit = value);
          },
          onDescendingChanged: (value) {
            if (value != null) setState(() => _descending = value);
          },
          onQuery: () => _loadRecords(forceRefresh: true),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: TrendChartSection(
                    metrics: _metrics,
                    selectedMetricIndex: _selectedMetricIndex,
                    records: _records,
                    onMetricChanged: (i) {
                      setState(() => _selectedMetricIndex = i);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildRecordList(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return RecordItem(
          record: record,
          isLast: index == _records.length - 1,
        );
      },
    );
  }
}
