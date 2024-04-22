import 'package:flutter/cupertino.dart';

class HeaderInputTextField extends StatelessWidget {
  final String text;
  final double marginTop;

  const HeaderInputTextField({
    required this.text,
    required this.marginTop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: marginTop),
      child: Text(
        text,
        style: const TextStyle(color: Color(0x85333333), fontSize: 13),
      ),
    );
  }
}
