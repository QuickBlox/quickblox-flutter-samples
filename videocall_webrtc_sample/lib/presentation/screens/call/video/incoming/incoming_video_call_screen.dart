import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/video_call/video_call_screen.dart';

import '../../../../utils/notification_utils.dart';
import '../../../users/users_screen.dart';
import '../../widgets/user_avatars.dart';
import '../../widgets/user_names.dart';
import 'incoming_video_call_screen_view_model.dart';

class IncomingVideoCallScreen extends StatelessWidget {
  List<QBUser> opponents;

  IncomingVideoCallLaunchedState state = IncomingVideoCallLaunchedState.FOREGROUND_STATE;

  static showAndClearStack(BuildContext context, List<QBUser> opponents,
      {IncomingVideoCallLaunchedState state = IncomingVideoCallLaunchedState.FOREGROUND_STATE}) {
    return Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => IncomingVideoCallScreen(opponents, state)), (_) => false);
  }

  final IncomingVideoCallScreenViewModel _viewModel = IncomingVideoCallScreenViewModel();

  IncomingVideoCallScreen(this.opponents, this.state, {super.key}) {
    _viewModel.init(opponents, state);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: ChangeNotifierProvider(
            create: (context) => _viewModel,
            child: Scaffold(
                backgroundColor: const Color(0xFF414E5B),
                body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  UserAvatars(opponentsLength: _viewModel.getOpponentsCount() - 1),
                  UserNames(users: opponents),
                  SizedBox(height: MediaQuery.of(context).size.height / 2 - 104),
                  const Text("Connecting to call...", style: TextStyle(color: Colors.white, fontSize: 20)),
                  Selector<IncomingVideoCallScreenViewModel, bool>(
                    selector: (_, viewModel) => viewModel.isCallEnd,
                    builder: (_, isCallEnd, __) {
                      if (isCallEnd) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop();
                          UsersScreen.showAndClearStack(context);
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Selector<IncomingVideoCallScreenViewModel, bool>(
                    selector: (_, viewModel) => viewModel.isCallAccepted,
                    builder: (_, callAccepted, __) {
                      if (callAccepted) {
                        _removeCurrentScreenAndShowVideoCallScreen(context);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Selector<IncomingVideoCallScreenViewModel, bool>(
                    selector: (_, viewModel) => viewModel.isCallRejected,
                    builder: (_, callRejected, __) {
                      if (callRejected) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop();
                          UsersScreen.showAndClearStack(context);
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Selector<IncomingVideoCallScreenViewModel, String?>(
                      selector: (_, viewModel) => viewModel.errorMessage,
                      builder: (_, errorMessage, __) {
                        if (errorMessage == null) {
                          NotificationUtils.hideSnackBar(context);
                        }
                        if (errorMessage?.isNotEmpty ?? false) {
                          _showErrorSnackBar(errorMessage!, context);
                        }
                        return const SizedBox.shrink();
                      }),
                ]))));
  }

  Future<void> _removeCurrentScreenAndShowVideoCallScreen(BuildContext context) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      VideoCallScreen.showAndClearStack(context, true, _viewModel.users);
    });
  }

  void _showErrorSnackBar(String errorMessage, BuildContext context, {VoidCallback? errorCallback}) {
    return NotificationUtils.showSnackBarError(context, errorMessage, errorCallback: errorCallback);
  }
}
