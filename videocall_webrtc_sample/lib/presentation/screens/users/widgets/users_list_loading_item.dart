import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/users_screen_view_model.dart';

class UsersListLoadingItem extends StatelessWidget {
  const UsersListLoadingItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<UsersScreenViewModel, bool>(
      selector: (_, viewModel) => viewModel.loadNextUsers,
      builder: (_, loadNextUsers, __) {
        if (loadNextUsers) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: CircularProgressIndicator()));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
