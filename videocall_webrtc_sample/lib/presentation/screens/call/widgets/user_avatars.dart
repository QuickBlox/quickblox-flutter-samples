import 'package:flutter/material.dart';

class UserAvatars extends StatelessWidget {
  final int opponentsLength;

  const UserAvatars({required this.opponentsLength, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildUserAvatar(),
      if (opponentsLength > 1)
        Padding(padding: const EdgeInsets.only(left: 8.0), child: _buildUserAvatar())
    ]);
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
        radius: 50.0,
        backgroundColor: Color(0xFFBCC1C5),
        child: Icon(Icons.person_outline, size: 50.0, color: Color(0xFF636D78)));
  }
}
