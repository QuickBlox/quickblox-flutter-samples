import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videocall_webrtc_sample/presentation/screens/login/login_screen_view_model.dart';
import 'package:videocall_webrtc_sample/presentation/screens/login/widgets/error_password_text_field.dart';
import 'package:videocall_webrtc_sample/presentation/screens/login/widgets/header_input_text_field.dart';
import 'package:videocall_webrtc_sample/presentation/screens/login/widgets/login_text_field.dart';

import '../../utils/notification_utils.dart';
import '../users/users_screen.dart';
import '../widgets/decorated_app_bar.dart';
import 'widgets/error_login_text_field.dart';
import 'widgets/login_button.dart';
import 'widgets/login_heading.dart';
import 'widgets/login_progress_indicator.dart';

class LoginScreen extends StatefulWidget {
  static show(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  static showAndClearStack(BuildContext context) {
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController loginTextController = TextEditingController();
  final TextEditingController passwordTextController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoginScreenViewModel _viewModel = LoginScreenViewModel();

  @override
  void dispose() {
    loginTextController.dispose();
    passwordTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginScreenViewModel>(
        create: (_) => _viewModel,
        child: Scaffold(
            appBar: DecoratedAppBar(
                appBar: AppBar(
                    centerTitle: true,
                    title: const Text('Enter to Video chat', style: TextStyle(
                        color: Colors.white
                    )),
                    backgroundColor: const Color(0xff3978fc))),
            body: Form(
                key: _formKey,
                child: ListView(padding: const EdgeInsets.only(left: 16, right: 16), children: [
                  const LoginHeading(),
                  const HeaderInputTextField(text: "Login", marginTop: 28),
                  LoginTextField(controller: loginTextController),
                  const ErrorLoginTextField(),
                  const HeaderInputTextField(text: "Password", marginTop: 16),
                  LoginTextField(controller: passwordTextController),
                  const ErrorPasswordTextField(),
                  LoginButton(
                    callback: (buttonContext) async {
                      String login = loginTextController.text.trim();
                      String password = passwordTextController.text.trim();

                      bool isValidCredentials = _viewModel.isValidCredentials(login, password);
                      if (isValidCredentials) {
                        await _viewModel.login(login, password);
                        FocusScope.of(buttonContext).unfocus();
                      }
                    },
                  ),
                  Selector<LoginScreenViewModel, bool>(
                    selector: (_, viewModel) => viewModel.loading,
                    builder: (_, loading, __) {
                      if (loading) {
                        return const LoginProgressIndicator();
                      }
                      if (!loading && _viewModel.isLoggedIn) {
                        _showUsersScreen(context);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Selector<LoginScreenViewModel, String?>(
                      selector: (_, viewModel) => viewModel.errorMessage,
                      builder: (_, errorMessage, __) {
                        if (errorMessage?.isNotEmpty ?? false) {
                          _showErrorSnackbar(errorMessage!, context);
                        }
                        return const SizedBox.shrink();
                      })
                ]))));
  }

  void _showUsersScreen(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UsersScreen.showAndClearStack(context);
    });
  }

  void _showErrorSnackbar(String errorMessage, BuildContext context) {
    NotificationUtils.showSnackBarError(context, errorMessage);
  }
}
