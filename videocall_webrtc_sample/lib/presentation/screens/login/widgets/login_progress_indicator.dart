import 'package:flutter/material.dart';

class LoginProgressIndicator extends StatelessWidget {
  const LoginProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: CircularProgressIndicator(color: Color(0xff3978fc)),
      ),
    );
  }
}
