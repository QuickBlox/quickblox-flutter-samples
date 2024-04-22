import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../login_screen_view_model.dart';

class ErrorLoginTextField extends StatelessWidget {
  const ErrorLoginTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<LoginScreenViewModel, bool>(
      selector: (_, viewModel) => viewModel.isLoginError,
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
          "E-mail or login should be in a range from 3 to 50. First character must be a letter.",
          style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }
}
