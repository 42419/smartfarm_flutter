import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_farm_flutter/pages/monitor/data_monitor_page.dart';
import 'package:smart_farm_flutter/pages/monitor/widgets/data_card.dart';
import 'package:smart_farm_flutter/services/mqtt_service.dart';

Future<void> _selectIndicator(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButton<String>).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('指标下拉联动实时数据卡片', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: DataMonitorPage()));
    await tester.pump();

    expect(find.byType(DataCard), findsNWidgets(4),
        reason: '初始（全部指标）应显示 4 个卡片');

    await _selectIndicator(tester, '温度指标');
    expect(find.byType(DataCard), findsOneWidget,
        reason: '温度指标应只显示温度卡片');

    await _selectIndicator(tester, '湿度指标');
    expect(find.byType(DataCard), findsNWidgets(2),
        reason: '湿度指标应显示空气湿度 + 土壤湿度卡片');

    await _selectIndicator(tester, '光照强度指标');
    expect(find.byType(DataCard), findsOneWidget,
        reason: '光照强度指标应只显示光照卡片');

    await _selectIndicator(tester, '全部指标');
    expect(find.byType(DataCard), findsNWidgets(4),
        reason: '切回全部指标应显示 4 个卡片');

    // 断开挂起的 MQTT 连接，清理 keepalive timer，避免测试结束时报 pending timer
    MqttService.instance.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
