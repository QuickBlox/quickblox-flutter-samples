import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../widgets/circular_button.dart';
import '../../../widgets/circular_button_with_state.dart';

class ControlsAudioCallButtons extends StatelessWidget {
  final void Function(bool isPressed) _onMute;
  final void Function(bool isPressed) _onSpeaker;
  final void Function() _onEndCall;

  const ControlsAudioCallButtons(
      {super.key, required onMute, required onSpeaker, required onEndCall})
      : _onMute = onMute,
        _onSpeaker = onSpeaker,
        _onEndCall = onEndCall;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          CircularButtonWithState(
              onPressed: (isPressed) => _onMute.call(isPressed),
              backgroundColor: const Color(0xFF202F3E),
              iconColor: Colors.white,
              icon: SvgPicture.asset('assets/icons/mute.svg', height: 35, width: 35),
              textBelowButton: 'Mute',
              isPressed: false),
          CircularButton(
              onPressed: () => _onEndCall.call(),
              backgroundColor: const Color(0xFFFF3B30),
              iconColor: Colors.white,
              icon: SvgPicture.asset('assets/icons/hang_up.svg', height: 60, width: 60),
              textBelowButton: 'End call'),
          CircularButtonWithState(
              onPressed: (isPressed) => _onSpeaker.call(isPressed),
              backgroundColor: const Color(0xFF202F3E),
              iconColor: Colors.white,
              icon: SvgPicture.asset('assets/icons/speaker.svg', height: 60, width: 60),
              textBelowButton: 'Speaker',
              isPressed: false)
        ]));
  }
}
