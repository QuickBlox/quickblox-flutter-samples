import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../widgets/circular_button.dart';

class IncomeVideoButtons extends StatelessWidget {
  final void Function() _onReject;
  final void Function() _onAccept;

  const IncomeVideoButtons({
    super.key,
    required void Function() onReject,
    required void Function() onAccept,
  })  : _onReject = onReject,
        _onAccept = onAccept;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          CircularButton(
              onPressed: () => _onReject.call(),
              backgroundColor: const Color(0xFFFF3B30),
              iconColor: Colors.white,
              icon: SvgPicture.asset('assets/icons/hang_up.svg', height: 35, width: 35),
              textBelowButton: 'Decline'),
          CircularButton(
              onPressed: () => _onAccept.call(),
              backgroundColor: const Color(0xFF49CF77),
              iconColor: Colors.white,
              icon: SvgPicture.asset('assets/icons/video.svg', height: 60, width: 60),
              textBelowButton: 'Video')
        ]));
  }
}
