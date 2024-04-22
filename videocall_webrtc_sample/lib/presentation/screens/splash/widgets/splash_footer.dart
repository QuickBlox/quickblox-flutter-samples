import 'package:flutter/material.dart';

class SplashFooter extends StatelessWidget {
  const SplashFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      child: const Padding(
        padding: EdgeInsets.only(bottom: 40),
        child: Text(
          'Flutter Video Call Sample',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
