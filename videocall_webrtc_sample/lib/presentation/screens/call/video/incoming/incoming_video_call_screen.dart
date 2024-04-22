import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/incoming/widgets/income_video_buttons.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/video_call/video_call_screen.dart';

import '../../../../utils/notification_utils.dart';
import '../../widgets/user_avatars.dart';
import '../../widgets/user_names.dart';
import 'incoming_video_call_screen_view_model.dart';

class IncomingVideoCallScreen extends StatelessWidget {
  static show(BuildContext context, List<QBUser?> opponents) {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingVideoCallScreen(opponents: opponents)));
  }

  final IncomingVideoCallScreenViewModel _viewModel = IncomingVideoCallScreenViewModel();

  IncomingVideoCallScreen({super.key, required List<QBUser?> opponents}) {
    _viewModel.init(opponents);
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
              UserAvatars(opponentsLength: _viewModel.getOpponentsCount()),
              UserNames(users: _viewModel.users),
              SizedBox(height: MediaQuery.of(context).size.height / 2 - 104),
              IncomeVideoButtons(
                onReject: () => _viewModel.rejectCall(),
                onAccept: () => _viewModel.acceptCall(),
              ),
              Selector<IncomingVideoCallScreenViewModel, bool>(
                selector: (_, viewModel) => viewModel.isCallEnd,
                builder: (_, isCallEnd, __) {
                  if (isCallEnd) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pop());
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
                    WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pop());
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
      VideoCallScreen.show(context, true, _viewModel.users);
    });
  }

  void _showErrorSnackBar(String errorMessage, BuildContext context, {VoidCallback? errorCallback}) {
    return NotificationUtils.showSnackBarError(context, errorMessage, errorCallback: errorCallback);
  }
}
