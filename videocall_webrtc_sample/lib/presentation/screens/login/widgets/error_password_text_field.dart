import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../login_screen_view_model.dart';

class ErrorPasswordTextField extends StatelessWidget {
  const ErrorPasswordTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<LoginScreenViewModel, bool>(
      selector: (_, viewModel) => viewModel.isPasswordError,
      builder: (_, isError, __) {
        if (isError) {
          return _buildErrorText();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorText() {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: Text(
          "Password cannot be empty",
          style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }
}
