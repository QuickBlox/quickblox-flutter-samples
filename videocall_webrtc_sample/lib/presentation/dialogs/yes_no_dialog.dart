import 'package:flutter/cupertino.dart';

import 'button_dialog.dart';

class YesNoDialog extends ButtonDialog {
  final VoidCallback onPressedPrimary;
  final VoidCallback onPressedSecondary;
  final String primaryButtonText;
  final String secondaryButtonText;

  YesNoDialog(
      {required this.onPressedPrimary,
      required this.onPressedSecondary,
      required this.primaryButtonText,
      required this.secondaryButtonText});

  @override
  List<Widget> getWidgets(BuildContext context) {
    return [
      _buildNoButton(secondaryButtonText, context),
      _buildYesButton(primaryButtonText, context)
    ];
  }

  Widget _buildYesButton(String title, BuildContext context) {
    return _buildButton(title, context, onPressedPrimary);
  }

  Widget _buildNoButton(String title, BuildContext context) {
    return _buildButton(title, context, onPressedSecondary);
  }

  Widget _buildButton(
      String title, BuildContext context, VoidCallback onPressed) {
    return buildButton(title, onPressed: onPressed);
  }
}
