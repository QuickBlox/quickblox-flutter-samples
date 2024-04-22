import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/widgets/circular_button.dart';

import '../../../widgets/circular_button_with_state.dart';
import 'oval_badge.dart';

class VideoCallButtons extends StatelessWidget {
  final void Function(bool isPressed) _onMute;
  final void Function(bool isPressed) _onDisableCamera;
  final void Function() _onSwitchCamera;
  final void Function() _onEndCall;

  const VideoCallButtons(
      {super.key, required onMute, required onDisableCamera, required onSwitchCamera, required onEndCall})
      : _onMute = onMute,
        _onDisableCamera = onDisableCamera,
        _onSwitchCamera = onSwitchCamera,
        _onEndCall = onEndCall;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Positioned(
      bottom: 0,
      child: Container(
          height: screenHeight / 4,
          width: screenWidth,
          color: Colors.black.withOpacity(0.5),
          child: Column(
            children: [
              const OvalBadge(),
              Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    CircularButtonWithState(
                        onPressed: (isPressed) => _onMute.call(isPressed),
                        backgroundColor: const Color(0xFF202F3E),
                        iconColor: Colors.white,
                        icon: SvgPicture.asset('assets/icons/mute.svg', height: 35, width: 35),
                        textBelowButton: 'Mute',
                        isPressed: false),
                    CircularButtonWithState(
                        onPressed: (isPressed) => _onDisableCamera.call(isPressed),
                        backgroundColor: const Color(0xFF202F3E),
                        iconColor: Colors.white,
                        icon: SvgPicture.asset('assets/icons/enable_camera.svg', height: 35, width: 35),
                        textBelowButton: 'Camera',
                        isPressed: false),
                    CircularButton(
                        onPressed: () => _onEndCall.call(),
                        backgroundColor: const Color(0xFFFF3B30),
                        iconColor: Colors.white,
                        icon: SvgPicture.asset('assets/icons/hang_up.svg', height: 35, width: 35),
                        textBelowButton: 'End call'),
                    CircularButtonWithState(
                        onPressed: (isPressed) => _onSwitchCamera.call(),
                        backgroundColor: const Color(0xFF202F3E),
                        iconColor: Colors.white,
                        icon: SvgPicture.asset('assets/icons/swap_camera.svg', height: 35, width: 35),
                        textBelowButton: 'Swap',
                        isPressed: false)
                  ]))
            ],
          )),
    );
  }
}
