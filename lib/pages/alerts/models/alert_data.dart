import 'package:flutter/material.dart';

class AlertData {
  final String id;
  final String borderColorKey;
  final String tagText;
  final String title;
  final DateTime time;
  final String content;
  final String primaryActionText;
  final IconData primaryActionIcon;
  final Color primaryActionColor;
  final bool isGenerated;

  AlertData({
    required this.id,
    required this.borderColorKey,
    required this.tagText,
    required this.title,
    required this.time,
    required this.content,
    required this.primaryActionText,
    required this.primaryActionIcon,
    required this.primaryActionColor,
    this.isGenerated = false,
  });
}
