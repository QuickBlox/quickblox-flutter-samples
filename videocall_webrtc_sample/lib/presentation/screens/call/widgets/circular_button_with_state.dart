import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';

typedef IsPressedCallback = void Function(bool isPressed);

class CircularButtonWithState extends StatefulWidget {
  final IsPressedCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final SvgPicture icon;
  final String? textBelowButton;
  final bool isPressed;

  const CircularButtonWithState({
    super.key,
    required this.onPressed,
    required this.iconColor,
    required this.backgroundColor,
    required this.icon,
    this.textBelowButton,
    required this.isPressed,
  });

  @override
  State<CircularButtonWithState> createState() => _CircularButtonWithState();
}

class _CircularButtonWithState extends State<CircularButtonWithState> {
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _isPressed = widget.isPressed;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isPressed ? widget.iconColor : widget.backgroundColor;
    final iconColor = _isPressed ? widget.backgroundColor : widget.iconColor;

    return Column(
      children: [
        ElevatedButton(
            onPressed: () {
              setState(() {
                _isPressed = !_isPressed;
              });
              widget.onPressed(_isPressed);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: const CircleBorder(),
              fixedSize: const Size.fromRadius(36),
            ),
            child: Center(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                      iconColor, // Fixed
                      BlendMode.srcATop),
                  child: widget.icon,
                ))),
        if (widget.textBelowButton != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.textBelowButton!,
              style: const TextStyle(
                  decoration: TextDecoration.none,fontSize:14, color: Colors.white),
            ),
          )
      ],
    );
  }
}
