import 'package:chat_sample/bloc/enter_chat_name/enter_chat_name_screen_bloc.dart';
import 'package:chat_sample/bloc/enter_chat_name/enter_chat_name_screen_events.dart';
import 'package:chat_sample/bloc/enter_chat_name/enter_chat_name_screen_states.dart';
import 'package:chat_sample/bloc/stream_builder_with_listener.dart';
import 'package:chat_sample/presentation/screens/base_screen_state.dart';
import 'package:chat_sample/presentation/screens/chat/chat_screen.dart';
import 'package:chat_sample/presentation/widgets/decorated_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/chat/constants.dart';

import '../../utils/notification_utils.dart';
import '../../widgets/progress.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class EnterChatNameScreen extends StatefulWidget {
  final int dialogType;
  final List<int> selectedUsersIds;

  EnterChatNameScreen(this.dialogType, this.selectedUsersIds);

  @override
  _EnterChatNameScreenState createState() =>
      _EnterChatNameScreenState(dialogType, selectedUsersIds);
}

class _EnterChatNameScreenState extends BaseScreenState<EnterChatNameScreenBloc> {
  int _dialogType;
  List<int> _selectedUsersIds;
  bool _allowFinish = false;

  _EnterChatNameScreenState(this._dialogType, this._selectedUsersIds);

  @override
  Widget build(BuildContext context) {
    initBloc(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: DecoratedAppBar(appBar: buildAppBar()),
        body: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: ListView(children: [
              Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: Text('Chat Name',
                      style: new TextStyle(color: Color(0xff6c7a92), fontSize: 13))),
              Container(
                child: Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: TextField(
                      onChanged: (chatName) {
                        bloc?.events?.add(ChangedChatNameEvent(chatName));
                      },
                      style: new TextStyle(fontSize: 17.0),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: new BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    )),
                decoration: BoxDecoration(
                  boxShadow: [
                    new BoxShadow(
                        color: Color.fromARGB(255, 217, 229, 255),
                        offset: new Offset(0, 6),
                        blurRadius: 11.0)
                  ],
                ),
              ),
              StreamBuilderWithListener<EnterChatNameScreenStates>(
                  stream: bloc?.states?.stream as Stream<EnterChatNameScreenStates>,
                  listener: (state) {
                    if (state is ChangedChatNameState) {
                      _allowFinish = state.allowFinish;
                    }
                    if (state is CreationFinishedState) {
                      _navigateToChatScreen(state.dialogId);
                    }
                    if (state is ErrorState) {
                      NotificationBarUtils.showSnackBarError(context, state.error);
                    }
                  },
                  builder: (context, state) {
                    if (!_allowFinish) {
                      return Container(
                          padding: EdgeInsets.only(top: 11),
                          child: Text("Must be in a range from 3 to 20 characters.",
                              style: new TextStyle(color: Color.fromRGBO(153, 169, 198, 1.0))));
                    }

                    return SizedBox.shrink();
                  }),
              _buildProgress(),
            ])));
  }

  AppBar buildAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: Color(0xff3978fc),
      title: Text("New Chat"),
      leading: new IconButton(
          icon: new Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          }),
      actions: <Widget>[
        StreamProvider<EnterChatNameScreenStates>(
            create: (context) => bloc?.states?.stream as Stream<EnterChatNameScreenStates>,
            initialData: ChangedChatNameState(false),
            child: Selector<EnterChatNameScreenStates, EnterChatNameScreenStates>(
              selector: (_, state) => state,
              shouldRebuild: (previous, next) {
                return next is ChangedChatNameState ||
                    next is CreatingDialogState ||
                    next is ErrorState;
              },
              builder: (_, state, __) {
                if (state is ChangedChatNameState && state.allowFinish || state is ErrorState) {
                  return TextButton(
                    onPressed: () {
                      if (_dialogType == QBChatDialogTypes.GROUP_CHAT &&
                          state is! CreatingDialogState) {
                        bloc?.events?.add(CreateGroupChatEvent(_selectedUsersIds));
                      }
                    },
                    child: Text(
                      'Finish',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  );
                }
                return Text("");
              },
            ))
      ],
    );
  }

  Widget _buildProgress() {
    return StreamProvider<EnterChatNameScreenStates>(
        create: (context) => bloc?.states?.stream as Stream<EnterChatNameScreenStates>,
        initialData: ChangedChatNameState(false),
        child: Selector<EnterChatNameScreenStates, EnterChatNameScreenStates>(
            selector: (_, state) => state,
            shouldRebuild: (previous, next) {
              return next is ChangedChatNameState ||
                  next is CreatingDialogState ||
                  next is ErrorState;
            },
            builder: (_, state, __) {
              if (state is CreatingDialogState) {
                return Progress(Alignment.center);
              } else {
                return SizedBox.shrink();
              }
            }));
  }

  void _navigateToChatScreen(String dialogId) {
    Navigator.pushAndRemoveUntil<void>(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(dialogId, true)),
        (route) => false);
  }
}
