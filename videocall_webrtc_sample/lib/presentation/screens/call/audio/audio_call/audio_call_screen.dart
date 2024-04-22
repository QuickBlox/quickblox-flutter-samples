import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/audio/audio_call/widgets/controls_audio_call_buttons.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/widgets/timer_widget.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/widgets/user_avatars.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/widgets/user_names.dart';

import '../../../../../managers/call_manager.dart';
import '../../../../utils/notification_utils.dart';
import 'audio_call_screen_view_model.dart';

class AudioCallScreen extends StatelessWidget {
  static show(BuildContext context, bool isIncoming, List<QBUser?> opponents) {
    return Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AudioCallScreen(isIncoming: isIncoming, opponents: opponents)));
  }

  final AudioCallScreenViewModel _viewModel = AudioCallScreenViewModel();

  AudioCallScreen({super.key, required bool isIncoming, required List<QBUser?> opponents}) {
    _viewModel.init(isIncoming, opponents);
  }

  @override
  Widget build(context) {
    return PopScope(
        canPop: false,
        child: ChangeNotifierProvider<AudioCallScreenViewModel>(
        create: (context) => _viewModel,
        child: Scaffold(
            backgroundColor: const Color(0xFF414E5B),
            body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              UserAvatars(opponentsLength: _viewModel.getOpponentsLength()),
              _buildTextCalling(),
              Selector<AudioCallScreenViewModel, bool>(
                  selector: (_, viewModel) => viewModel.isStartedCall,
                  builder: (_, isStarted, __) {
                    return isStarted ? const TimerWidget() : const SizedBox.shrink();
                  }),
              UserNames(users: _viewModel.opponents ?? []),
              SizedBox(height: MediaQuery.of(context).size.height / 2 - 120),
              ControlsAudioCallButtons(
                onEndCall: () => _viewModel.hangUpCall(),
                onMute: (isPressed) {
                  bool isNeedMute = !isPressed;
                  _viewModel.enableAudio(isNeedMute);
                },
                onSpeaker: (isPressed) {
                  if (isPressed) {
                    _viewModel.switchAudioOutput(AudioOutputTypes.LOUDSPEAKER);
                  } else {
                    _viewModel.switchAudioOutput(AudioOutputTypes.EAR_SPEAKER);
                  }
                },
              ),
              Selector<AudioCallScreenViewModel, String?>(
                  selector: (_, viewModel) => viewModel.errorMessage,
                  builder: (_, errorMessage, __) {
                    if (errorMessage == null) {
                      _hideErrorSnackBar(context);
                    }
                    if (errorMessage?.isNotEmpty ?? false) {
                      _showErrorSnackBar(errorMessage!, context);
                    }
                    return const SizedBox.shrink();
                  }),
              Selector<AudioCallScreenViewModel, bool>(
                selector: (_, viewModel) => viewModel.isEndCall,
                builder: (_, isCallEnd, __) {
                  if (isCallEnd) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => Navigator.of(context).pop());
                  }
                  return const SizedBox.shrink();
                },
              ),
            ]))));
  }

  Widget _buildTextCalling() {
    return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Calling to',
            style:
                TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Color(0xFF90979F))));
  }

  void _showErrorSnackBar(String errorMessage, BuildContext context,
      {VoidCallback? errorCallback}) {
    return NotificationUtils.showSnackBarError(context, errorMessage, errorCallback: errorCallback);
  }

  void _hideErrorSnackBar(BuildContext context) {
    return NotificationUtils.hideSnackBar(context);
  }
}
