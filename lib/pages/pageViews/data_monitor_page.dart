import 'package:flutter/material.dart';

class DataMonitorPage extends StatelessWidget {
  const DataMonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据监测')),
      body: const Center(child: Text('数据监测页面')),
    );
  }
}
