import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/users_screen.dart';

import '../../../../utils/notification_utils.dart';
import '../../widgets/user_avatars.dart';
import '../../widgets/user_names.dart';
import '../audio_call/audio_call_screen.dart';
import 'incoming_audio_call_screen_view_model.dart';

class IncomingAudioCallScreen extends StatefulWidget {
  List<QBUser?> opponents;
  IncomingAudioCallLaunchedState state = IncomingAudioCallLaunchedState.FOREGROUND_STATE;

  IncomingAudioCallScreen(this.opponents, this.state);

  static showAndClearStack(BuildContext context,
      {required List<QBUser?> opponents,
      IncomingAudioCallLaunchedState state = IncomingAudioCallLaunchedState.FOREGROUND_STATE}) {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => IncomingAudioCallScreen(opponents, state)), (_) => false);
  }

  @override
  State<IncomingAudioCallScreen> createState() => _IncomingAudioCallScreenState();
}

class _IncomingAudioCallScreenState extends State<IncomingAudioCallScreen> {
  final IncomingAudioCallScreenViewModel _viewModel = IncomingAudioCallScreenViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.init(widget.opponents, widget.state);
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
                  UserAvatars(opponentsLength: widget.opponents.length - 1),
                  UserNames(users: widget.opponents),
                  SizedBox(height: MediaQuery.of(context).size.height / 2 - 104),
                  const Text("Connecting to call...",
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                  Selector<IncomingAudioCallScreenViewModel, bool>(
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
                  Selector<IncomingAudioCallScreenViewModel, bool>(
                    selector: (_, viewModel) => viewModel.callAccepted,
                    builder: (_, callAccepted, __) {
                      if (callAccepted) {
                        _removeCurrentScreenAndShowAudioCallScreen();
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Selector<IncomingAudioCallScreenViewModel, bool>(
                    selector: (_, viewModel) => viewModel.callRejected,
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
                  Selector<IncomingAudioCallScreenViewModel, String?>(
                      selector: (_, viewModel) => viewModel.errorMessage,
                      builder: (_, errorMessage, __) {
                        if (errorMessage?.isNotEmpty ?? false) {
                          _showErrorSnackbar(errorMessage!, context);
                        }
                        return const SizedBox.shrink();
                      }),
                ]))));
  }

  Future<void> _removeCurrentScreenAndShowAudioCallScreen() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<QBUser?> opponents = await _viewModel.getOpponents();
      Navigator.of(context).pop();
      AudioCallScreen.showAndClearStack(context, true, opponents);
    });
  }

  void _showErrorSnackbar(String errorMessage, BuildContext context,
      {VoidCallback? errorCallback}) {
    return NotificationUtils.showSnackBarError(context, errorMessage, errorCallback: errorCallback);
  }
}
