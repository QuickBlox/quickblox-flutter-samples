import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../login_screen_view_model.dart';

class LoginButton extends StatelessWidget {
  final void Function(BuildContext) callback;
  const LoginButton({
    super.key,
    required this.callback,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<LoginScreenViewModel, bool>(
      selector: (_, viewModel) => viewModel.loading,
      builder: (_, isLoggingIn, __) {
        return Container(
          padding: const EdgeInsets.only(top: 42, left: 64, right: 64),
          child: ElevatedButton(
            onPressed: isLoggingIn ? null :() {
                callback(context);
            },
            style: ButtonStyle(
              elevation: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.disabled) ? null : 3),
              shadowColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                  ? const Color(0xff99a9c6)
                  : const Color(0x403978fc)),
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                  ? const Color(0xff99a9c6)
                  : const Color(0xff3978fc)),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 17, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
