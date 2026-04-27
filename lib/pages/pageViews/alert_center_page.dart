import 'package:flutter/material.dart';

class AlertCenterPage extends StatelessWidget {
  const AlertCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('告警中心')),
      body: const Center(child: Text('告警中心页面')),
    );
  }
}
