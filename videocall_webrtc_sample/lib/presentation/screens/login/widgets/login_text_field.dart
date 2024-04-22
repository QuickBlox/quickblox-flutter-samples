import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;

  const LoginTextField({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 11),
      decoration: _buildTextFieldDecoration(),
      child: TextFormField(
        controller: controller,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 17),
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          errorMaxLines: 2,
          contentPadding: const EdgeInsets.all(10),
          filled: true,
          fillColor: Colors.white,
          border: _buildWhiteBorder(),
          focusedBorder: _buildWhiteBorder(),
          enabledBorder: _buildWhiteBorder(),
        ),
      ),
    );
  }

  BoxDecoration _buildTextFieldDecoration() {
    return const BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Color.fromARGB(255, 217, 229, 255),
          offset: Offset(0, 6),
          blurRadius: 11.0,
        ),
      ],
    );
  }

  OutlineInputBorder _buildWhiteBorder() {
    return const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
    );
  }
}
