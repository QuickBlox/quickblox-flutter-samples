import 'dart:async';

import 'package:flutter/material.dart';

class NotificationUtils {
  NotificationUtils._();

  static void showSnackBarError(
    BuildContext context,
    String errorMessage, {
    VoidCallback? errorCallback,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hideSnackBar(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          errorMessage,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(days: 365),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.fromLTRB(6.0, 0.5, 0.5, 0.5),
        action: SnackBarAction(
          label: errorCallback == null ? 'Hide' : 'Retry',
          textColor: Colors.blueAccent,
          onPressed: () {
            if (errorCallback != null) {
              errorCallback.call();
            }
            hideSnackBar(context);
          },
        ),
      ));
    });
  }

  static void showConnectivityIndicator(
    BuildContext context,
    bool isConnected,
    bool isWiFi,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      String label = isConnected ? "Connected" : "Disconnected";
      Color background = isConnected ? Colors.green : Colors.redAccent;
      Icon icon = isConnected
          ? isWiFi
              ? const Icon(Icons.wifi, color: Colors.white)
              : const Icon(Icons.signal_cellular_alt, color: Colors.white)
          : const Icon(Icons.wifi_off, color: Colors.white);
      Duration delay = isConnected ? const Duration(seconds: 2) : const Duration(days: 365);

      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
        backgroundColor: background,
        leading: icon,
        leadingPadding: const EdgeInsets.only(left: 15.0),
        content: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("DISMISS", style: TextStyle(color: Colors.white)),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
          ),
        ],
      ));

      Timer(delay, () {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      });
    });
  }

  static void hideSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(
      reason: SnackBarClosedReason.dismiss,
    );
  }

  static void showResult(BuildContext context, String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(duration: const Duration(seconds: 1), content: Text(text)));
    });
  }
}
