import 'package:flutter/material.dart';
import 'base_dialog.dart';

abstract class ButtonDialog extends BaseDialog {
  @protected
  Widget buildButton(String title, {VoidCallback? onPressed}) {
    return TextButton(onPressed: onPressed, child: Text(title));
  }
}
