import 'dart:async';

import 'package:chat_sample/bloc/select_users/select_users_screen_bloc.dart';
import 'package:chat_sample/bloc/select_users/select_users_screen_events.dart';
import 'package:chat_sample/bloc/select_users/select_users_screen_states.dart';
import 'package:chat_sample/bloc/stream_builder_with_listener.dart';
import 'package:chat_sample/models/user_wrapper.dart';
import 'package:chat_sample/presentation/screens/base_screen_state.dart';
import 'package:chat_sample/presentation/screens/enter_chat_name/enter_chat_name_screen.dart';
import 'package:chat_sample/presentation/screens/select_users/select_users_screen_item.dart';
import 'package:chat_sample/presentation/screens/select_users/select_users_screen_loading_item.dart';
import 'package:chat_sample/presentation/utils/notification_utils.dart';
import 'package:chat_sample/presentation/widgets/decorated_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/chat/constants.dart';

import '../../widgets/progress.dart';
import '../chat/chat_screen.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class SelectUsersScreen extends StatefulWidget {
  final String _dialogId;

  SelectUsersScreen(this._dialogId);

  @override
  _SelectUsersScreenState createState() => _SelectUsersScreenState(_dialogId);
}

class _SelectUsersScreenState extends BaseScreenState<SelectUsersScreenBloc> {
  ScrollController? _scrollController;
  String _dialogId;

  _SelectUsersScreenState(this._dialogId);

  final _searchDelay = SearchTimer(milliseconds: 1000);
  bool _search = false;

  @override
  void dispose() {
    _scrollController?.removeListener(_scrollListener);
    _scrollController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initBloc(context);
    if (_dialogId.isNotEmpty) {
      bloc?.setArgs(_dialogId);
    }

    _scrollController = ScrollController();
    _scrollController?.addListener(_scrollListener);

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: DecoratedAppBar(appBar: buildAppBar()),
        body: Stack(children: [
          StreamBuilderWithListener<SelectUsersScreenStates>(
            stream: bloc?.states?.stream as Stream<SelectUsersScreenStates>,
            listener: (state) {
              if (state is ErrorState) {
                NotificationBarUtils.showSnackBarError(context, state.error);
              }
              if (state is CreateDialogErrorState) {
                NotificationBarUtils.showSnackBarError(context, state.error);
              }
              if (state is CreatedDialogState) {
                _navigateToChatScreen(state.dialogId);
              }
            },
            builder: (context, state) {
              return SizedBox.shrink();
            },
          ),
          Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                  padding: EdgeInsets.only(left: 12, right: 10),
                  child: SizedBox(
                      child: SvgPicture.asset('assets/icons/search.svg'), height: 28, width: 28)),
              Expanded(
                  child: TextFormField(
                keyboardType: TextInputType.text,
                maxLines: 1,
                minLines: 1,
                maxLength: 25,
                onChanged: (text) {
                  if (text.length >= 3) {
                    _search = true;
                    _searchDelay.run(() => bloc?.events?.add(SearchUsersEvent(text)));
                  }

                  if (text.length == 0) {
                    _search = false;
                    bloc?.events?.add(LoadUsersEvent());
                  }
                },
                decoration: const InputDecoration(
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: "Search",
                    hintStyle: TextStyle(fontSize: 15, color: Color(0xFF6C7A92)),
                    counterText: ""),
              ))
            ]),
            Expanded(
                child: RawScrollbar(
              isAlwaysShown: false,
              thickness: 3,
              radius: Radius.circular(3),
              thumbColor: Colors.blue,
              controller: _scrollController,
              child: StreamProvider<SelectUsersScreenStates>(
                initialData: LoadUsersInProgressState(),
                create: (context) => bloc?.states?.stream as Stream<SelectUsersScreenStates>,
                child: Selector<SelectUsersScreenStates, SelectUsersScreenStates>(
                  selector: (_, state) => state,
                  shouldRebuild: (previous, next) {
                    return next is LoadUsersSuccessState || next is LoadUsersInProgressState;
                  },
                  builder: (_, state, __) {
                    if (state is LoadUsersSuccessState) {
                      List<QBUserWrapper> users = state.users;

                      if (users.isEmpty) {
                        return Container(
                            padding: EdgeInsets.only(top: 20),
                            child: Text("No user with that name",
                                style: TextStyle(fontSize: 17, color: Color(0xFF6C7A92))));
                      }
                      return ListView.builder(
                        addAutomaticKeepAlives: true,
                        itemCount: users.length,
                        shrinkWrap: true,
                        controller: _scrollController,
                        itemBuilder: (BuildContext context, int index) {
                          if (users.length > 1 && index == users.length - 1) {
                            return SelectUsersScreenLoadingItem();
                          } else {
                            return SelectUsersScreenItem(users[index]);
                          }
                        },
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ),
            )),
          ]),
          _buildProgress()
        ]));
  }

  AppBar buildAppBar() {
    const int ONE_USER = 1;
    return AppBar(
      centerTitle: true,
      backgroundColor: Color(0xff3978fc),
      title: StreamProvider<SelectUsersScreenStates>(
          create: (context) => bloc?.states?.stream as Stream<SelectUsersScreenStates>,
          initialData: ChangedSelectedUsersState([]),
          child: Selector<SelectUsersScreenStates, SelectUsersScreenStates>(
              selector: (_, state) => state,
              shouldRebuild: (previous, next) {
                return next is ChangedSelectedUsersState;
              },
              builder: (_, state, __) {
                return Column(children: <Widget>[
                  Text(_dialogId.isNotEmpty ? 'Add Users' : 'New Chat'),
                  _buildSubtitle(state as ChangedSelectedUsersState)
                ]);
              })),
      leading: new IconButton(
          icon: new Icon(Icons.arrow_back_ios),
          onPressed: () {
            NotificationBarUtils.hideSnackBar(context);
            bloc?.events?.add(LeaveSelectUsersScreenEvent());
            Navigator.pop(context);
          }),
      actions: <Widget>[
        StreamProvider<SelectUsersScreenStates>(
            create: (context) => bloc?.states?.stream as Stream<SelectUsersScreenStates>,
            initialData: ChangedSelectedUsersState([]),
            child: Selector<SelectUsersScreenStates, SelectUsersScreenStates>(
              selector: (_, state) => state,
              shouldRebuild: (previous, next) {
                return next is ChangedSelectedUsersState ||
                    next is CreateDialogErrorState ||
                    next is CreatingDialogState;
              },
              builder: (_, state, __) {
                if ((state is ChangedSelectedUsersState && state.usersIds.isNotEmpty) ||
                    state is CreateDialogErrorState) {
                  return TextButton(
                      child: Text(_dialogId.isNotEmpty ? "Add" : "Create",
                          style: TextStyle(color: Colors.white, fontSize: 17)),
                      onPressed: () {
                        if (state is ChangedSelectedUsersState) {
                          NotificationBarUtils.hideSnackBar(context);
                          bloc?.events?.add(LeaveSelectUsersScreenEvent());
                          if (_dialogId.isNotEmpty) {
                            Navigator.pop(context, state.usersIds);
                          } else {
                            if (state.usersIds.length > ONE_USER) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EnterChatNameScreen(
                                          QBChatDialogTypes.GROUP_CHAT, state.usersIds),
                                    ));
                              });
                            } else {
                              bloc?.events?.add(CreatePrivateChatEvent(state.usersIds));
                            }
                          }
                        }
                      });
                }
                return SizedBox.shrink();
              },
            ))
      ],
    );
  }

  Widget _buildProgress() {
    return StreamProvider<SelectUsersScreenStates>(
        create: (context) => bloc?.states?.stream as Stream<SelectUsersScreenStates>,
        initialData: LoadUsersInProgressState(),
        child: Selector<SelectUsersScreenStates, SelectUsersScreenStates>(
            selector: (_, state) => state,
            shouldRebuild: (previous, next) {
              return next is CreatingDialogState ||
                  next is LoadUsersInProgressState ||
                  next is LoadUsersSuccessState ||
                  next is CreateDialogErrorState ||
                  next is ChangedSelectedUsersState ||
                  next is ErrorState;
            },
            builder: (_, state, __) {
              if (state is CreatingDialogState || state is LoadUsersInProgressState) {
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
        (route) => route.isFirst);
  }

  void _scrollListener() {
    if (_scrollController == null) {
      return;
    }
    double? maxScroll = _scrollController?.position.maxScrollExtent;
    double? currentScroll = _scrollController?.position.pixels;
    if (maxScroll == currentScroll) {
      if (_search) {
        bloc?.events?.add(SearchNextUsersEvent());
      } else {
        bloc?.events?.add(LoadNextUsersEvent());
      }
    }
  }

  Widget _buildSubtitle(ChangedSelectedUsersState state) {
    int usersCount = state.usersIds.length;

    String subtitle = usersCount.toString() + " user" + (usersCount == 1 ? "" : "s") + " selected";
    return Text('$subtitle',
        style: TextStyle(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.normal));
  }
}

class SearchTimer {
  final int? milliseconds;
  VoidCallback? action;
  Timer? _timer;

  SearchTimer({this.milliseconds});

  run(VoidCallback callback) {
    if (milliseconds != null) {
      _timer?.cancel();
      _timer = Timer(Duration(milliseconds: milliseconds!), callback);
    }
  }
}
