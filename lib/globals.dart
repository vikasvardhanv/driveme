
import 'package:flutter/material.dart';

/// Global key to show snackbars without needing a BuildContext
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Show a premium snackbar from anywhere in the app
void showPremiumSnackBar({
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final state = scaffoldMessengerKey.currentState;
  if (state == null) return;

  state.hideCurrentSnackBar();
  state.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      elevation: 8,
      duration: duration,
    ),
  );
}
