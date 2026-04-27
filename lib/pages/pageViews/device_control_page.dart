import 'package:flutter/material.dart';

class DeviceControlPage extends StatelessWidget {
  const DeviceControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设备控制')),
      body: const Center(child: Text('设备控制页面')),
    );
  }
}
