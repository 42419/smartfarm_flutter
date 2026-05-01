import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

const AnimationStyle _toastAnimationStyle = AnimationStyle(
  curve: Curves.easeOutBack,
  reverseCurve: Curves.easeInCubic,
  duration: Duration(milliseconds: 360),
  reverseDuration: Duration(milliseconds: 220),
);

void showAppToast(String message) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null || !messenger.mounted) {
    return;
  }

  final bool isSuccess = message.contains('成功');
  final Color backgroundColor = isSuccess
      ? const Color(0xFF1F7A4D)
      : const Color(0xFFB9382F);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.1, color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        elevation: 8,
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        duration: const Duration(milliseconds: 1800),
      ),
      snackBarAnimationStyle: _toastAnimationStyle,
    );
}
