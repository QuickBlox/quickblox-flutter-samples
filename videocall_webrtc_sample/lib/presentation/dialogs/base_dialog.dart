import 'package:flutter/material.dart';

abstract class BaseDialog {
  List<Widget> getWidgets(BuildContext context);

  void show(BuildContext context,
      {String title = "", bool dismissTouchOutside = false}) {
    List<Widget> widgets = getWidgets(context);

    Widget dialog = _build(widgets, title);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
          barrierDismissible: dismissTouchOutside,
          context: context,
          builder: (_) => dialog);
    });
  }

  Widget _build(List<Widget> widgets, String title) {
    return AlertDialog(
        title: _buildTitle(title),
        shape: _buildShapeBorder(),
        actions: widgets);
  }

  Widget _buildTitle(String title) {
    return Text(title);
  }

  ShapeBorder _buildShapeBorder() {
    return const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)));
  }
}
