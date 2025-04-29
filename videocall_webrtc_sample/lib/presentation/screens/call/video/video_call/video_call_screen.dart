import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/video_call/video_call_screen_view_model.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/video_call/widgets/controls_video_call_buttons.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/video_call/widgets/video_call_app_bar.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/video_call/widgets/video_tracks_widget.dart';

import '../../../../utils/notification_utils.dart';
import '../../../users/users_screen.dart';

class VideoCallScreen extends StatelessWidget {
  static show(BuildContext context, bool isIncoming, List<QBUser> callUsers) {
    return Navigator.push(
        context, MaterialPageRoute(builder: (_) => VideoCallScreen(isIncoming: isIncoming, callUsers: callUsers)));
  }

  static showAndClearStack(BuildContext context, bool isIncoming, List<QBUser> callUsers) {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => VideoCallScreen(isIncoming: isIncoming, callUsers: callUsers)), (_) => false);
  }

  final List<QBUser> callUsers;
  final bool isIncoming;

  final VideoCallScreenViewModel _viewModel = VideoCallScreenViewModel();

  VideoCallScreen({
    super.key,
    required this.isIncoming,
    required this.callUsers,
  }) {
    _viewModel.init(isIncoming, callUsers);
  }

  @override
  Widget build(context) {
    return PopScope(
        canPop: false,
        child: ChangeNotifierProvider<VideoCallScreenViewModel>(
            create: (context) => _viewModel,
            child: Container(
                color: const Color(0xFF414E5B),
                child: Stack(children: [
                  VideoTracksWidget(_viewModel.getVideoCallEntities()),
                  VideoCallAppBar(text: _viewModel.getOpponentNames(callUsers)),
                  VideoCallButtons(
                      onMute: (isPressed) {
                        bool isNeedMute = !isPressed;
                        _viewModel.enableAudio(isNeedMute);
                      },
                      onDisableCamera: (isPressed) {
                        bool isNeedDisable = !isPressed;
                        _viewModel.enableVideo(isNeedDisable);
                      },
                      onSwitchCamera: () => _viewModel.switchCamera(),
                      onEndCall: () {
                        _viewModel.hangUpCall();
                      }),
                  Selector<VideoCallScreenViewModel, String?>(
                    selector: (_, viewModel) => viewModel.opponentActionMessage,
                    builder: (_, message, __) {
                      if (message?.isNotEmpty ?? false) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                            duration: const Duration(seconds: 1),
                            content: Text(message!),
                          ));
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Selector<VideoCallScreenViewModel, bool>(
                    selector: (_, viewModel) => viewModel.isEndCall,
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
                  Selector<VideoCallScreenViewModel, String?>(
                      selector: (_, viewModel) => viewModel.errorMessage,
                      builder: (_, errorMessage, __) {
                        if (errorMessage == null) {
                          NotificationUtils.hideSnackBar(context);
                        }
                        if (errorMessage?.isNotEmpty ?? false) {
                          NotificationUtils.showSnackBarError(context, errorMessage!);
                        }
                        return const SizedBox.shrink();
                      })
                ]))));
  }
}
