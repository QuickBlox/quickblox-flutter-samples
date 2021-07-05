import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DialogUtils {
  static DialogUtils _instance = DialogUtils.internal();

  DialogUtils.internal();

  factory DialogUtils() => _instance;

  static void showError(BuildContext context, PlatformException exception) {
    String? error =
        exception.code.isNotEmpty ? exception.code : exception.message;

    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(error != null ? error : "unexpected error"),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  static void showOneBtn(BuildContext context, String titleText) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(titleText),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  static void showTwoBtn(BuildContext context, String titleText,
      Function accept, Function decline) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(titleText),
            actions: <Widget>[
              TextButton(
                  child: Text("Accept"),
                  onPressed: () {
                    accept(null);
                    Navigator.pop(context);
                  }),
              TextButton(
                  child: Text("Decline"),
                  onPressed: () {
                    decline(null);
                    Navigator.pop(context);
                  }),
            ],
          );
        });
  }
}
