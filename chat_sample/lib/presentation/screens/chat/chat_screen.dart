import 'dart:async';

import 'package:chat_sample/bloc/chat/chat_screen_bloc.dart';
import 'package:chat_sample/bloc/chat/chat_screen_events.dart';
import 'package:chat_sample/bloc/chat/chat_screen_states.dart';
import 'package:chat_sample/bloc/stream_builder_with_listener.dart';
import 'package:chat_sample/models/message_wrapper.dart';
import 'package:chat_sample/presentation/screens/base_screen_state.dart';
import 'package:chat_sample/presentation/screens/chat_info/chat_info_screen.dart';
import 'package:chat_sample/presentation/screens/delivered_to/delivered_viewed_screen.dart';
import 'package:chat_sample/presentation/screens/dialogs/dialogs_screen.dart';
import 'package:chat_sample/presentation/utils/color_util.dart';
import 'package:chat_sample/presentation/utils/notification_utils.dart';
import 'package:chat_sample/presentation/utils/random_util.dart';
import 'package:chat_sample/presentation/widgets/decorated_app_bar.dart';
import 'package:chat_sample/presentation/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/chat/constants.dart';

import '../../managers/typing_satus_manager.dart';
import '../../navigation/navigation_service.dart';
import '../../navigation/router.dart';
import 'chat_screen_list_item.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class ChatScreen extends StatefulWidget {
  final String _dialogId;
  final bool _isNewChat;

  ChatScreen(this._dialogId, this._isNewChat);

  @override
  _ChatScreenState createState() => _ChatScreenState(_dialogId, _isNewChat);
}

class _ChatScreenState extends BaseScreenState<ChatScreenBloc> {
  static const int CHAT_INFO_MENU_ITEM = 0;
  static const int LEAVE_CHAT_MENU_ITEM = 1;
  static const int DELETE_CHAT_MENU_ITEM = 2;

  static const int FORWARD_MESSAGE_MENU_ITEM = 0;
  static const int DELIVERED_TO_MENU_ITEM = 1;
  static const int VIEWED_BY_MENU_ITEM = 2;

  String _dialogId;
  int _dialogType = 0;
  bool _hasMore = true;
  bool _isNewChat;

  ScrollController? _scrollController;
  TextEditingController? _inputController = TextEditingController();

  _ChatScreenState(this._dialogId, this._isNewChat);

  @override
  void dispose() {
    TypingStatusManager.cancelTimer();
    _scrollController?.removeListener(_scrollListener);
    _scrollController = null;
    _inputController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initBloc(context);
    bloc?.setArgs(ChatArguments(_dialogId, _isNewChat));

    _scrollController = ScrollController();
    _scrollController?.addListener(_scrollListener);

    return Scaffold(
      appBar: DecoratedAppBar(appBar: _buildAppBar()),
      body: Column(
        children: [
          Expanded(
            child: Stack(children: [
              Container(
                  color: Color(0xfff1f1f1),
                  child: RawScrollbar(
                    thumbVisibility: false,
                    thickness: 3,
                    controller: _scrollController,
                    radius: Radius.circular(3),
                    thumbColor: Colors.blue,
                    child: StreamProvider<ChatScreenStates>(
                      create: (context) => bloc?.states?.stream as Stream<ChatScreenStates>,
                      initialData: LoadMessagesSuccessState([], false),
                      child: Selector<ChatScreenStates, ChatScreenStates>(
                          selector: (_, state) => state,
                          shouldRebuild: (previous, next) {
                            return next is LoadMessagesSuccessState;
                          },
                          builder: (_, state, __) {
                            if (state is LoadMessagesSuccessState) {
                              this._hasMore = state.hasMore;
                            }
                            var tapPosition;

                            return GroupedListView<QBMessageWrapper, DateTime>(
                              elements: (state as LoadMessagesSuccessState).messages,
                              order: GroupedListOrder.DESC,
                              reverse: true,
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              floatingHeader: true,
                              useStickyGroupSeparators: true,
                              groupBy: (QBMessageWrapper message) =>
                                  DateTime(message.date.year, message.date.month, message.date.day),
                              groupHeaderBuilder: (QBMessageWrapper message) =>
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Container(
                                  margin: EdgeInsets.only(top: 7, bottom: 7),
                                  padding: EdgeInsets.only(left: 16, right: 16, top: 3, bottom: 3),
                                  decoration: BoxDecoration(
                                      color: Color(0xffd9e3f7),
                                      borderRadius: BorderRadius.all(Radius.circular(11))),
                                  child: Text(_buildHeaderDate(message.qbMessage.dateSent),
                                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                                )
                              ]),
                              itemBuilder: (context, QBMessageWrapper message) => GestureDetector(
                                  child: ChatListItem(
                                      Key(RandomUtil.getRandomString(10)), message, _dialogType),
                                  onTapDown: (details) {
                                    tapPosition = details.globalPosition;
                                  },
                                  onLongPress: () {
                                    RenderBox? overlay = Overlay.of(context)
                                        ?.context
                                        .findRenderObject() as RenderBox;

                                    List<PopupMenuItem> messageMenuItems = [
                                      PopupMenuItem(
                                          child: Text("Forward",
                                              style: TextStyle(color: Colors.black54)),
                                          value: FORWARD_MESSAGE_MENU_ITEM),
                                    ];

                                    List<PopupMenuItem> ownMessageMenuItems = [
                                      PopupMenuItem(
                                          child: Text("Delivered to",
                                              style: TextStyle(color: Colors.black54)),
                                          value: DELIVERED_TO_MENU_ITEM),
                                      PopupMenuItem(
                                          child: Text("Viewed by",
                                              style: TextStyle(color: Colors.black54)),
                                          value: VIEWED_BY_MENU_ITEM),
                                    ];

                                    if (!message.isIncoming) {
                                      messageMenuItems.addAll(ownMessageMenuItems);
                                    }
                                    showMenu(
                                            context: context,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.all(Radius.circular(15.0))),
                                            color: Colors.white,
                                            position: RelativeRect.fromRect(
                                                tapPosition & const Size(40, 40),
                                                Offset.zero & overlay.size),
                                            elevation: 8,
                                            items: messageMenuItems)
                                        .then((value) {
                                      switch (value) {
                                        case FORWARD_MESSAGE_MENU_ITEM:
                                          forwardMessage();
                                          break;
                                        case DELIVERED_TO_MENU_ITEM:
                                          showMessageDetailsScreen(message, isDeliveredTo: true);
                                          break;
                                        case VIEWED_BY_MENU_ITEM:
                                          showMessageDetailsScreen(message, isDeliveredTo: false);
                                          break;
                                      }
                                    });
                                  }),
                              controller: _scrollController,
                            );
                          }),
                    ),
                  )),
              _buildProgress()
            ]),
          ),
          _buildEnterMessageRow()
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return StreamProvider<ChatScreenStates>(
        create: (context) => bloc?.states?.stream as Stream<ChatScreenStates>,
        initialData: ChatConnectingState(),
        child: Selector<ChatScreenStates, ChatScreenStates>(
            selector: (_, state) => state,
            shouldRebuild: (previous, next) {
              return next is ChatConnectingState ||
                  next is ChatConnectingErrorState ||
                  next is UpdateChatErrorState ||
                  next is LoadMessagesInProgressState ||
                  next is LoadMessagesSuccessState;
            },
            builder: (_, state, __) {
              if (state is ChatConnectingErrorState) {
                NotificationBarUtils.showSnackBarError(context, state.error, errorCallback: () {
                  bloc?.events?.add(ConnectChatEvent());
                });
              }
              if (state is ChatConnectingState || state is LoadMessagesInProgressState) {
                return Progress(Alignment.center);
              } else {
                return SizedBox.shrink();
              }
            }));
  }

  Widget _buildEnterMessageRow() {
    return SafeArea(
      child: Column(
        children: [
          _buildTypingIndicator(),
          Container(
            color: Colors.white,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 50,
                  height: 50,
                  child: IconButton(
                      icon: SvgPicture.asset('assets/icons/attachment.svg'),
                      onPressed: () {
                        NotificationBarUtils.showSnackBarError(
                            context, "This feature is not available now");
                      }),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: 2, bottom: 2),
                    child: TextField(
                      controller: _inputController,
                      onChanged: (text) {
                        TypingStatusManager.typing((TypingStates state) {
                          switch (state) {
                            case TypingStates.start:
                              bloc?.events?.add(StartTypingEvent());
                              break;
                            case TypingStates.stop:
                              bloc?.events?.add(StopTypingEvent());
                              break;
                          }
                        });
                      },

                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(fontSize: 15.0, color: Colors.black87),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent)),
                          hintStyle: TextStyle(color: Colors.black26),
                          hintText: "Send message..."),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  child: IconButton(
                    icon: SvgPicture.asset('assets/icons/send.svg'),
                    onPressed: () {
                      TypingStatusManager.cancelTimer();
                      bloc?.events?.add(SendMessageEvent(_inputController?.text));
                      _inputController?.text = "";
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamProvider<ChatScreenStates>(
        create: (context) => bloc?.states?.stream as Stream<ChatScreenStates>,
        initialData: OpponentStoppedTypingState(),
        child: Selector<ChatScreenStates, ChatScreenStates>(
            selector: (_, state) => state,
            shouldRebuild: (previous, next) {
              return next is OpponentIsTypingState ||
                  next is OpponentStoppedTypingState ||
                  next is LoadMessagesInProgressState;
            },
            builder: (_, state, __) {
              if (state is OpponentIsTypingState) {
                return Container(
                  color: Color(0xfff1f1f1),
                  height: 35,
                  child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 16),
                        Text(_makeTypingStatus(state.typingNames),
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xff6c7a92),
                                fontStyle: FontStyle.italic))
                      ]),
                );
              } else {
                return SizedBox.shrink();
              }
            }));
  }

  AppBar _buildAppBar() {
    String dialogName = "";
    return AppBar(
      centerTitle: true,
      backgroundColor: Color(0xff3978fc),
      leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            _leaveChatScreen();
          }),
      actions: <Widget>[
        _buildPopupMenuItems(),
      ],
      title: StreamBuilderWithListener<ChatScreenStates>(
          stream: bloc?.states?.stream as Stream<ChatScreenStates>,
          listener: (state) {
            if (state is ChatConnectedState) {
              bloc?.events?.add(UpdateChatEvent());
            }
            if (state is UpdateChatSuccessState) {
              if (state.dialog.name != null) {
                dialogName = state.dialog.name!;
              }
              _dialogType = state.dialog.type ?? 0;
            }
            if (state is LoadMessagesSuccessState) {
              NotificationBarUtils.hideSnackBar(context);
            }
            if (state is ReturnToDialogsState) {
              NotificationBarUtils.hideSnackBar(context);
              _leaveChatScreen();
            }
            if (state is ErrorState) {
              NotificationBarUtils.showSnackBarError(context, state.error);
            }
            if (state is UpdateChatErrorState) {
              NotificationBarUtils.showSnackBarError(context, state.error, errorCallback: () {
                bloc?.events?.add(UpdateChatEvent());
              });
            }
            if (state is LeaveChatErrorState) {
              NotificationBarUtils.showSnackBarError(context, state.error, errorCallback: () {
                bloc?.events?.add(LeaveChatEvent());
              });
            }
            if (state is DeleteChatErrorState) {
              NotificationBarUtils.showSnackBarError(context, state.error, errorCallback: () {
                bloc?.events?.add(DeleteChatEvent());
              });
            }
            if (state is LoadNextMessagesErrorState) {
              NotificationBarUtils.showSnackBarError(context, state.error, errorCallback: () {
                bloc?.events?.add(LoadNextMessagesPageEvent());
              });
            }
            if (state is SendMessageErrorState && state.messageToSend != null) {
              NotificationBarUtils.showSnackBarError(context, state.error, errorCallback: () {
                bloc?.events?.add(SendMessageEvent(state.messageToSend));
              });
            }
          },
          builder: (context, state) {
            if (state.data is UpdateChatInProgressState ||
                state.data is LoadMessagesInProgressState) {
              return Container(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                alignment: Alignment.center,
                child: SizedBox(
                    height: 15, width: 15, child: Progress(Alignment.center, color: Colors.white)),
              );
            }

            if (state.data is LoadMessagesSuccessState ||
                state.data is OpponentIsTypingState ||
                state.data is OpponentStoppedTypingState ||
                state.data is UpdateChatSuccessState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      child: _dialogType == QBChatDialogTypes.CHAT
                          ? _generateAvatarFromName(dialogName)
                          : null),
                  SizedBox(width: 4),
                  Text(dialogName, style: TextStyle(fontSize: 17))
                ],
              );
            }
            return SizedBox.shrink();
          }),
    );
  }

  void _leaveChatScreen() {
    bloc?.events?.add(LeaveChatScreenEvent());
    NotificationBarUtils.hideSnackBar(context);
    if (_isNewChat) {
      NavigationService().pushReplacementNamed(DialogsScreenRoute);
    } else {
      Navigator.pop(context, DialogsScreen.FLAG_UPDATE);
    }
  }

  Widget _buildPopupMenuItems() {
    List<PopupMenuItem>? menuItems = <PopupMenuItem>[];
    return StreamProvider<ChatScreenStates>(
      create: (context) => bloc?.states?.stream as Stream<ChatScreenStates>,
      initialData: ChatConnectingState(),
      child: Selector<ChatScreenStates, ChatScreenStates>(
          selector: (_, state) => state,
          shouldRebuild: (previous, next) {
            return next is LoadMessagesInProgressState;
          },
          builder: (_, state, __) {
            switch (_dialogType) {
              case QBChatDialogTypes.PUBLIC_CHAT:
                return SizedBox.shrink();
              case QBChatDialogTypes.GROUP_CHAT:
                menuItems = [
                  PopupMenuItem(
                      child: Text("Chat Info", style: TextStyle(color: Colors.black54)),
                      value: CHAT_INFO_MENU_ITEM),
                  PopupMenuItem(
                      child: Text("Leave Chat", style: TextStyle(color: Colors.black54)),
                      value: LEAVE_CHAT_MENU_ITEM)
                ];
                break;
              case QBChatDialogTypes.CHAT:
                menuItems = [
                  PopupMenuItem(
                      child: Text("Delete Chat", style: TextStyle(color: Colors.black54)),
                      value: DELETE_CHAT_MENU_ITEM)
                ];
                break;
              default:
                menuItems = null;
            }
            Widget popupMenu = PopupMenuButton(
                color: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
                onSelected: (item) {
                  switch (item) {
                    case CHAT_INFO_MENU_ITEM:
                      _startChatInfoScreen(context);
                      break;
                    case LEAVE_CHAT_MENU_ITEM:
                      _showDialogExitChat(context, "Leave", LeaveChatEvent());
                      break;
                    case DELETE_CHAT_MENU_ITEM:
                      _showDialogExitChat(context, "Delete", DeleteChatEvent());
                      break;
                  }
                },
                itemBuilder: (context) => menuItems!);
            return popupMenu;
          }),
    );
  }

  void _showDialogExitChat(BuildContext context, String label, ChatScreenEvents event) {
    Widget okButton = TextButton(
        onPressed: () {
          bloc?.events?.add(event);
          Navigator.pop(context, DialogsScreen.FLAG_UPDATE);
        },
        child: Text(label, style: TextStyle(color: Colors.blue)));

    Widget cancelButton = TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text("Cancel", style: TextStyle(color: Colors.blue)));

    AlertDialog alert = AlertDialog(
        backgroundColor: Colors.white,
        content: Text("$label chat?"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        actions: [okButton, cancelButton]);

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return alert;
        });
  }

  void _scrollListener() {
    double? maxScroll = _scrollController?.position.maxScrollExtent;
    double? currentScroll = _scrollController?.position.pixels;
    if (maxScroll == currentScroll && _hasMore) {
      bloc?.events?.add(LoadNextMessagesPageEvent());
    }
  }

  String _buildHeaderDate(int? timeStamp) {
    String completedDate = "";
    DateFormat dayFormat = DateFormat("d MMMM");
    DateFormat lastYearFormat = DateFormat("dd.MM.yy");

    DateTime now = DateTime.now();
    var today = DateTime(now.year, now.month, now.day);
    var yesterday = DateTime(now.year, now.month, now.day - 1);

    if (timeStamp == null) {
      timeStamp = 0;
    }
    DateTime messageTime = DateTime.fromMicrosecondsSinceEpoch(timeStamp * 1000);
    DateTime messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);

    if (today == messageDate) {
      completedDate = "Today";
    } else if (yesterday == messageDate) {
      completedDate = "Yesterday";
    } else if (now.year == messageTime.year) {
      completedDate = dayFormat.format(messageTime);
    } else {
      completedDate = lastYearFormat.format(messageTime);
    }

    return completedDate;
  }

  String _makeTypingStatus(List<String> usersName) {
    const int MAX_NAME_SIZE = 20;
    const int ONE_USER = 1;
    const int TWO_USERS = 2;

    String result = "";
    int namesCount = usersName.length;

    switch (namesCount) {
      case ONE_USER:
        String firstUser = usersName[0];
        if (firstUser.length <= MAX_NAME_SIZE) {
          result = firstUser + " is typing...";
        } else {
          result = firstUser.substring(0, MAX_NAME_SIZE - 1) + "… is typing...";
        }
        break;
      case TWO_USERS:
        String firstUser = usersName[0];
        String secondUser = usersName[1];
        if ((firstUser + secondUser).length > MAX_NAME_SIZE) {
          firstUser = _getModifiedUserName(firstUser);
          secondUser = _getModifiedUserName(secondUser);
        }
        result = firstUser + " and " + secondUser + " are typing...";
        break;
      default:
        String firstUser = usersName[0];
        String secondUser = usersName[1];
        String thirdUser = usersName[2];

        if ((firstUser + secondUser + thirdUser).length <= MAX_NAME_SIZE) {
          result = firstUser + ", " + secondUser + ", " + thirdUser + " are typing...";
        } else {
          firstUser = _getModifiedUserName(firstUser);
          secondUser = _getModifiedUserName(secondUser);
          result = firstUser +
              ", " +
              secondUser +
              " and " +
              (namesCount - 2).toString() +
              " more are typing...";
          break;
        }
    }
    return result;
  }

  String _getModifiedUserName(String name) {
    const int MAX_NAME_SIZE = 10;
    if (name.length >= MAX_NAME_SIZE) {
      name = name.substring(0, (MAX_NAME_SIZE) - 1) + "…";
    }
    return name;
  }

  Future<void> _startChatInfoScreen(BuildContext context) async {
    NotificationBarUtils.hideSnackBar(context);
    bloc?.events?.add(LeaveChatScreenEvent());
    var resultList = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatInfoScreen(_dialogId),
        ));
    if (resultList != null) {
      bloc?.events?.add(ReturnChatScreenEvent());
      bloc?.events?.add(UsersAddedEvent(resultList));
    }
  }

  Widget _generateAvatarFromName(String name) {
    return Container(
      width: 26,
      height: 26,
      decoration: new BoxDecoration(
          color: Color(ColorUtil.getColor(name)),
          borderRadius: new BorderRadius.all(Radius.circular(20))),
      child: Center(
        child: Text(
          '${name.substring(0, 1).toUpperCase()}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Future<void> showMessageDetailsScreen(QBMessageWrapper message, {bool? isDeliveredTo}) async {
    if (message.id == null) {
      NotificationBarUtils.showSnackBarError(context, "Message has no Id");
      return;
    }
    NotificationBarUtils.hideSnackBar(context);
    bloc?.events?.add(LeaveChatScreenEvent());
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DeliveredViewedScreen(_dialogId, message.id!, isDeliveredTo ?? true),
        )).then((value) {
      bloc?.events?.add(ReturnChatScreenEvent());
    });
  }

  void forwardMessage() {
    NotificationBarUtils.showSnackBarError(context, "This feature is not available now");
  }
}
