
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CircularButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final SvgPicture icon;
  final String? textBelowButton;

  const CircularButton(
      {super.key,
      required this.onPressed,
      required this.iconColor,
      required this.backgroundColor,
      required this.icon,
      this.textBelowButton});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                shape: const CircleBorder(),
                fixedSize: const Size.fromRadius(36)),
            child: Center(child: icon)),
        if (textBelowButton != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              textBelowButton!,
              style: const TextStyle( decoration: TextDecoration.none,fontSize:14, color: Colors.white),
            ),
          )
      ],
    );
  }
}
