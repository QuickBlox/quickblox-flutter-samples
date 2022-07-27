import 'package:chat_sample/bloc/base_bloc.dart';
import 'package:chat_sample/bloc/select_users/select_users_screen_bloc.dart';
import 'package:chat_sample/bloc/select_users/select_users_screen_states.dart';
import 'package:chat_sample/presentation/screens/base_screen_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class SelectUsersScreenLoadingItem extends StatefulWidget {
  @override
  _SelectUsersScreenLoadingItemState createState() => _SelectUsersScreenLoadingItemState();
}

class _SelectUsersScreenLoadingItemState extends BaseScreenState<SelectUsersScreenBloc> {
  Bloc? _bloc;

  @override
  Widget build(BuildContext context) {
    _bloc = Provider.of<SelectUsersScreenBloc>(context, listen: false);

    return Container(
        child: StreamProvider<SelectUsersScreenStates>(
            initialData: LoadUsersSuccessState([]),
            create: (context) => _bloc?.states?.stream as Stream<SelectUsersScreenStates>,
            child: Selector<SelectUsersScreenStates, SelectUsersScreenStates>(
              selector: (_, state) => state,
              shouldRebuild: (previous, next) {
                return next is LoadNextUsersInProgressState || next is LoadUsersSuccessState;
              },
              builder: (_, state, __) {
                if (state is LoadNextUsersInProgressState) {
                  return Center(
                      child: Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.blue), strokeWidth: 5.0)));
                }
                return Text("");
              },
            )));
  }
}
