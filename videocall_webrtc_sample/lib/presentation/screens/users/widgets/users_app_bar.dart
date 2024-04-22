import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:videocall_webrtc_sample/entities/user_entity.dart';
import 'package:videocall_webrtc_sample/presentation/dialogs/yes_no_dialog.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/callback/app_bar_callback.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/users_screen_view_model.dart';

class UsersAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppBarCallback callback;

  const UsersAppBar({super.key, required this.callback});

  @override
  Widget build(BuildContext context) {
    return AppBar(
        centerTitle: true,
        leadingWidth: 120,
        title: Column(
          children: [
            const Text('Users', style: TextStyle(color: Colors.white)),
            _buildAppBarSubtitle()
          ],
        ),
        backgroundColor: const Color(0xff3978fc),
        actions: [_buildCallButton(context)],
        leading: Row(children: [
          Selector<UsersScreenViewModel, bool>(
              selector: (_, viewModel) => viewModel.isLoggedIn,
              builder: (_, isLoggedIn, __) {
                if (!isLoggedIn) {
                  callback.onLogIn();
                }
                return IconButton(
                    icon: SvgPicture.asset('assets/icons/exit.svg', height: 35, width: 35),
                    onPressed: () {
                      callback.onLogOut();
                    });
              }),
          Selector<UsersScreenViewModel, bool>(
              selector: (_, viewModel) => viewModel.isLoggingOut,
              builder: (_, isLoggingOut, __) {
                if (isLoggingOut) {
                  return _buildThinProgressIndicator();
                }
                return const SizedBox.shrink();
              })
        ]));
  }

  Widget _buildAppBarSubtitle() {
    return Selector<UsersScreenViewModel, List<UserEntity>>(
      selector: (_, viewModel) => viewModel.selectedUsersSet.toList(),
      builder: (_, selectedUsers, __) {
        int usersCount = selectedUsers.length;
        String subtitle = "$usersCount user${usersCount == 1 ? "" : "s"} selected";
        return Text(subtitle,
            style: const TextStyle(
                fontSize: 13, color: Colors.white60, fontWeight: FontWeight.normal));
      },
    );
  }

  Widget _buildCallButton(BuildContext context) {
    return TextButton(
      onPressed: () => YesNoDialog(
              onPressedPrimary: () {
                Navigator.pop(context);
                callback.onVideoCall();
              },
              onPressedSecondary: () {
                Navigator.pop(context);
                callback.onAudioCall();
              },
              primaryButtonText: 'Video Call',
              secondaryButtonText: 'Audio Call')
          .show(context, title: 'Choose the type of call', dismissTouchOutside: true),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Icons.call,
            color: Colors.white,
          ),
          SizedBox(width: 5),
          Text(
            'Call',
            style: TextStyle(color: Colors.white, fontSize: 18.0),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildThinProgressIndicator() {
    return const SizedBox(
      height: 25,
      width: 25,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
    );
  }

  @override
  Size get preferredSize => throw UnimplementedError();
}
