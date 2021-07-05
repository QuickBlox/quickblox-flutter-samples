import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showResult(GlobalKey<ScaffoldState> scaffoldKey, String text) {
    if (scaffoldKey.currentState != null) {
      ScaffoldMessenger.maybeOf(scaffoldKey.currentContext!)!.showSnackBar(
          SnackBar(duration: const Duration(seconds: 1), content: Text(text)));
    } else {
      print(text);
    }
  }
}
