import 'package:flutter/material.dart';

class BlueButton extends StatelessWidget {
  const BlueButton(this._title, this._onPressed, {Key? key}) : super(key: key);

  final String _title;
  final Function _onPressed;

  Widget build(BuildContext context) {
    return MaterialButton(
        minWidth: 200,
        child: Text(_title),
        color: Colors.blue,
        textColor: Colors.white,
        onPressed: () => _onPressed.call());
  }
}
