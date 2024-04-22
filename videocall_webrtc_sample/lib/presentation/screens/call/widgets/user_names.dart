import 'package:flutter/material.dart';
import 'package:quickblox_sdk/models/qb_user.dart';

class UserNames extends StatelessWidget {
  final List<QBUser?> users;

  const UserNames({required this.users, super.key});

  @override
  Widget build(BuildContext context) {
    String firstOpponentName = "UserName";
    if (users.isNotEmpty) {
      firstOpponentName = users[0]?.fullName ?? "UserName";
    }
    return Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(firstOpponentName, style: _buildUsernameTextStyle()),
          _buildPluralityUsersNames(),
        ]));
  }

  TextStyle _buildUsernameTextStyle() {
    return const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white);
  }

  Widget _buildPluralityUsersNames() {
    String other = users.length == 2 ? "other" : "others";

    if (users.length > 1) {
      return Text(' and ${users.length - 1} $other', style: _buildUsernameTextStyle());
    } else {
      return const SizedBox.shrink();
    }
  }
}
