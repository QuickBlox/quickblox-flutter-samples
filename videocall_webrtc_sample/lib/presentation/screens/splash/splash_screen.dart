import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:videocall_webrtc_sample/presentation/screens/login/login_screen.dart';
import 'package:videocall_webrtc_sample/presentation/screens/splash/splash_screen_view_model.dart';
import 'package:videocall_webrtc_sample/presentation/screens/splash/widgets/splash_footer.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/users_screen.dart';
import 'package:videocall_webrtc_sample/presentation/utils/notification_utils.dart';

import 'widgets/splash_progress_bar.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _showLoginScreen(BuildContext context) {
    Future.delayed(Duration.zero, () => LoginScreen.showAndClearStack(context));
  }

  void _showUsersScreen(BuildContext context) {
    Future.delayed(Duration.zero, () => UsersScreen.showAndClearStack(context));
  }

  @override
  Widget build(BuildContext context) {
    final SplashScreenViewModel viewModel = SplashScreenViewModel();
    viewModel.enableLogging();
    viewModel.initQBSDK();
    viewModel.checkSavedUserAndLogin();

    return ChangeNotifierProvider<SplashScreenViewModel>(
      create: (_) => viewModel,
      child: Scaffold(
        body: Container(
          color: const Color(0xff3978fc),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Center(child: SvgPicture.asset('assets/icons/qb-logo.svg')),
              Selector<SplashScreenViewModel, bool>(
                selector: (_, viewModel) => viewModel.loading,
                builder: (_, isLoading, __) {
                  if (isLoading) {
                    return const SplashProgressBar();
                  }

                  if (viewModel.isLoggedIn) {
                    _showUsersScreen(context);
                  } else {
                    _showLoginScreen(context);
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SplashFooter(),
              Selector<SplashScreenViewModel, String?>(
                selector: (_, viewModel) => viewModel.errorMessage,
                builder: (_, errorMessage, __) {
                  if (errorMessage?.isNotEmpty == true) {
                    _showErrorSnackbar(errorMessage!, context);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String errorMessage, BuildContext context) {
    NotificationUtils.showSnackBarError(context, errorMessage, errorCallback: () {
      final SplashScreenViewModel viewModel =
          Provider.of<SplashScreenViewModel>(context, listen: false);
      viewModel.hideError();
      viewModel.checkSavedUserAndLogin();
    });
  }
}
