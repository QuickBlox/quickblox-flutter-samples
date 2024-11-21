import 'package:chat_sample/bloc/dialogs/dialogs_screen_bloc.dart';
import 'package:chat_sample/bloc/dialogs/dialogs_screen_events.dart';
import 'package:chat_sample/bloc/dialogs/dialogs_screen_states.dart';
import 'package:chat_sample/bloc/stream_builder_with_listener.dart';
import 'package:chat_sample/presentation/navigation/navigation_service.dart';
import 'package:chat_sample/presentation/navigation/router.dart';
import 'package:chat_sample/presentation/screens/base_screen_state.dart';
import 'package:chat_sample/presentation/screens/chat/chat_screen.dart';
import 'package:chat_sample/presentation/utils/notification_utils.dart';
import 'package:chat_sample/presentation/utils/random_util.dart';
import 'package:chat_sample/presentation/widgets/decorated_app_bar.dart';
import 'package:chat_sample/presentation/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';

import 'dialogs_screen_list_item.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class DialogsScreen extends StatefulWidget {
  static const String FLAG_UPDATE = "update";

  @override
  _DialogsScreenState createState() => _DialogsScreenState();
}

class _DialogsScreenState extends BaseScreenState<DialogsScreenBloc> {
  bool _deleteState = false;

  @override
  Widget build(BuildContext context) {
    initBloc(context);

    return Scaffold(
        appBar: DecoratedAppBar(appBar: _buildAppBar()),
        body: Stack(
          children: [
            StreamProvider<DialogsScreenStates>(
              create: (context) => bloc?.states?.stream as Stream<DialogsScreenStates>,
              initialData: ChatConnectingState(),
              child: Selector<DialogsScreenStates, DialogsScreenStates>(
                selector: (_, state) => state,
                shouldRebuild: (previous, next) {
                  return next is UpdateChatsSuccessState;
                },
                builder: (_, state, __) {
                  if (state is UpdateChatsSuccessState) {
                    NotificationBarUtils.hideSnackBar(context);
                    List<QBDialog?> dialogs = state.dialogs;
                    return RefreshIndicator(
                      color: Colors.blue,
                      backgroundColor: Colors.white,
                      onRefresh: () {
                        bloc?.events?.add(UpdateChatsEvent());
                        return Future(() {});
                      },
                      child: ListView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: dialogs.length,
                        itemBuilder: (BuildContext context, int index) {
                          if (dialogs[index] == null || dialogs[index]!.id == null) {
                            return SizedBox.shrink();
                          }

                          return GestureDetector(
                            child: DialogsListItem(
                                Key(RandomUtil.getRandomString(10)), dialogs[index]!, _deleteState),
                            onLongPress: () {
                              bloc?.events?.add(ModeDeleteChatsEvent());
                            },
                            onTap: () async {
                              if (!_deleteState) {
                                NotificationBarUtils.hideSnackBar(context);
                                bloc?.events?.add(LeaveDialogsScreenEvent());
                                var result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(dialogs[index]!.id!, false),
                                    ));
                                if (result == DialogsScreen.FLAG_UPDATE) {
                                  bloc?.events?.add(UpdateChatsEvent());
                                  bloc?.events?.add(ReturnDialogsScreenEvent());
                                }
                              }
                            },
                          );
                        },
                      ),
                    );
                  }
                  return Text("");
                },
              ),
            ),
            _buildProgress()
          ],
        ));
  }

  Widget _buildProgress() {
    return StreamBuilderWithListener<DialogsScreenStates>(
        stream: bloc?.states?.stream as Stream<DialogsScreenStates>,
        listener: (state) {
          if (state is UpdateChatsErrorState) {
            NotificationBarUtils.showSnackBarError(context, state.error);
          }
          if (state is SavedUserErrorState) {
            NotificationBarUtils.showSnackBarError(context, "Current User is not saved");
          }
          if (state is ErrorState) {
            NotificationBarUtils.showSnackBarError(context, state.error);
          }
          if (state is DeleteErrorState) {
            NotificationBarUtils.showSnackBarError(context, state.error);
          }
          if (state is ConnectionTypeChanged) {
            NotificationBarUtils.showConnectivityIndicator(
                context, state.isConnected, state.isWiFi);
          }
          if (state is LogoutErrorState) {
            NotificationBarUtils.showSnackBarError(this.context, state.error);
          }
        },
        builder: (context, state) {
          if (state.data is UpdateChatsInProgressState || state.data is DeleteInProgressState) {
            return Progress(Alignment.center);
          }
          return SizedBox.shrink();
        });
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: Color(0xff3978fc),
      title: StreamProvider<DialogsScreenStates>(
          create: (context) => bloc?.states?.stream as Stream<DialogsScreenStates>,
          initialData: ChatConnectingState(),
          child: Selector<DialogsScreenStates, DialogsScreenStates>(
            selector: (_, state) => state,
            shouldRebuild: (previous, next) {
              return next is ChangedChatsToDeleteState ||
                  next is ModeDeleteChatsState ||
                  next is ModeListChatsState;
            },
            builder: (_, state, __) {
              if (state is ChangedChatsToDeleteState) {
                return Column(
                  children: <Widget>[
                    Text('Delete Chats'),
                    Text('${state.dialogsCount} chats selected', style: TextStyle(fontSize: 13))
                  ],
                );
              }
              if (state is ModeDeleteChatsState) {
                return Column(
                  children: <Widget>[
                    Text('Delete Chats'),
                    Text('${0} chats selected', style: TextStyle(fontSize: 13))
                  ],
                );
              }
              if (state is ModeListChatsState) {
                bloc?.events?.add(UpdateChatsEvent());
              }
              return Text('Chats');
            },
          )),
      leading: StreamProvider<DialogsScreenStates>(
        create: (context) => bloc?.states?.stream as Stream<DialogsScreenStates>,
        initialData: ChatConnectingState(),
        child: Selector<DialogsScreenStates, DialogsScreenStates>(
          selector: (_, state) => state,
          shouldRebuild: (previous, next) {
            return next is ModeListChatsState ||
                next is ModeDeleteChatsState ||
                next is LogoutSuccessState;
          },
          builder: (_, state, __) {
            if (state is ModeDeleteChatsState) {
              _deleteState = true;
              return IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () {
                  bloc?.events?.add(ModeListChatsEvent());
                },
              );
            }
            if (state is ModeListChatsState) {
              _deleteState = false;
            }
            if (state is LogoutSuccessState) {
              NotificationBarUtils.hideSnackBar(context);
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                NavigationService().pushReplacementNamed(LoginScreenRoute);
              });
            }
            return IconButton(
                icon: SvgPicture.asset('assets/icons/exit.svg'),
                onPressed: () {
                  _showDialogLogout(context);
                });
          },
        ),
      ),
      actions: <Widget>[
        StreamProvider<DialogsScreenStates>(
            initialData: ModeListChatsState(),
            create: (context) => bloc?.states?.stream as Stream<DialogsScreenStates>,
            child: Selector<DialogsScreenStates, DialogsScreenStates>(
              selector: (_, state) => state,
              shouldRebuild: (previous, next) {
                return next is ModeDeleteChatsState ||
                    next is ModeListChatsState ||
                    next is ChangedChatsToDeleteState;
              },
              builder: (_, state, __) {
                if (state is ChangedChatsToDeleteState && state.dialogsCount > 0) {
                  return TextButton(
                    onPressed: () {
                      bloc?.events?.add(DeleteChatsEvent());
                    },
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  );
                }
                if (state is ModeListChatsState) {
                  return Row(children: <Widget>[
                    IconButton(
                        icon: SvgPicture.asset('assets/icons/info.svg'),
                        onPressed: () {
                          NotificationBarUtils.hideSnackBar(context);
                          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                            NavigationService().pushNamed(AppInfoScreenRoute);
                          });
                        }),
                    IconButton(
                        icon: SvgPicture.asset('assets/icons/add.svg'),
                        onPressed: () async {
                          NotificationBarUtils.hideSnackBar(context);
                          Navigator.pushNamed(context, SelectUsersScreenRoute).then((value) {
                            bloc?.events?.add(UpdateChatsEvent());
                          });
                        }),
                  ]);
                }
                return SizedBox.shrink();
              },
            ))
      ],
    );
  }

  void _showDialogLogout(BuildContext context) {
    Widget okButton = TextButton(
        onPressed: () async {
          NotificationBarUtils.hideSnackBar(context);
          Navigator.pop(context);
          bloc?.events?.add(LogoutEvent());
        },
        child: Text("Logout", style: TextStyle(color: Colors.blue)));

    Widget cancelButton = TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text("Cancel", style: TextStyle(color: Colors.blue)));

    AlertDialog alert = AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        content: Text("Press Logout to continue"),
        actionsPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        actions: [okButton, cancelButton]);

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return alert;
        });
  }
}
