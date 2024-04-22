import 'package:flutter/material.dart';

class SplashProgressBar extends StatelessWidget{
  const SplashProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      child: const Padding(
        padding: EdgeInsets.only(bottom: 150),
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4.0),
      ),
    );
  }
}