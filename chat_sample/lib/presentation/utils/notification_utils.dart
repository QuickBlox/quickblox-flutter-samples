import 'dart:async';

import 'package:flutter/material.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class NotificationBarUtils {
  NotificationBarUtils._();

  static void showSnackBarError(BuildContext context, String errorMessage,
      {void errorCallback()?}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: Text(errorMessage, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black87,
          duration: Duration(days: 365),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(8.0),
          padding: EdgeInsets.fromLTRB(6.0, 0.5, 0.5, 0.5),
          action: SnackBarAction(
            label: errorCallback == null ? 'Hide' : 'Retry',
            textColor: Colors.blueAccent,
            onPressed: () {
              if (errorCallback != null) {
                errorCallback.call();
              }
              ScaffoldMessenger.of(context)
                  .hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
            },
          ),
        ))
        .closed
        .then((value) => {
              if (value == SnackBarClosedReason.swipe) {showSnackBarError(context, errorMessage)}
            });
  }

  static void showConnectivityIndicator(BuildContext context, bool isConnected, bool isWiFi) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    String label = isConnected ? "Connected" : "Disconnected";
    Color background = isConnected ? Colors.green : Colors.redAccent;
    Icon icon = isConnected
        ? isWiFi
            ? Icon(Icons.wifi, color: Colors.white)
            : Icon(Icons.signal_cellular_alt, color: Colors.white)
        : Icon(Icons.wifi_off, color: Colors.white);
    Duration delay = isConnected ? Duration(seconds: 2) : Duration(days: 365);

    ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
      padding: EdgeInsets.only(left: 5.0, right: 5.0),
      backgroundColor: background,
      leading: icon,
      leadingPadding: EdgeInsets.only(left: 15.0),
      content: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        child: Text(label, style: TextStyle(color: Colors.white)),
      ),
      actions: [
        TextButton(
          child: Text("DISMISS", style: TextStyle(color: Colors.white)),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          },
        ),
      ],
    ));

    Timer(delay, () {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }

  static void hideSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
  }
}
