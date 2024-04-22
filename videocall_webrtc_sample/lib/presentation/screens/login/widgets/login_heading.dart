import 'package:flutter/cupertino.dart';

class LoginHeading extends StatelessWidget {
  const LoginHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 28),
      child: const Text(
        'Please enter your login \n and password',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 17),
      ),
    );
  }
}