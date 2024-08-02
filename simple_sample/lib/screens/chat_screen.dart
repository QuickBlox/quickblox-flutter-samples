import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/chat/constants.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';
import 'package:quickblox_sdk/models/qb_filter.dart';
import 'package:quickblox_sdk/models/qb_message.dart';
import 'package:quickblox_sdk/models/qb_sort.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/credentials.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';
import 'package:quickblox_sdk_example/widgets/blue_app_bar.dart';
import 'package:quickblox_sdk_example/widgets/blue_button.dart';

class ChatScreen extends StatefulWidget {
  static show(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ChatScreen()));
  }

  @override
  State<StatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _dialogId;
  String? _messageId;

  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _systemMessageSubscription;
  StreamSubscription? _deliveredMessageSubscription;
  StreamSubscription? _readMessageSubscription;
  StreamSubscription? _userTypingSubscription;
  StreamSubscription? _userStopTypingSubscription;
  StreamSubscription? _connectedSubscription;
  StreamSubscription? _connectionClosedSubscription;
  StreamSubscription? _reconnectionFailedSubscription;
  StreamSubscription? _reconnectionSuccessSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    QB.settings.enableXMPPLogging();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print("LIFECYCLE_STATE: ${state.name}");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();

    unsubscribeNewMessage();
    unsubscribeSystemMessage();
    unsubscribeDeliveredMessage();
    unsubscribeReadMessage();
    unsubscribeUserTyping();
    unsubscribeUserStopTyping();
    unsubscribeConnected();
    unsubscribeConnectionClosed();
    unsubscribeReconnectionFailed();
    unsubscribeReconnectionSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: BlueAppBar('Chat'),
        body: Center(
            child: SingleChildScrollView(
                child: Column(children: [
          BlueButton('connect', () => connect()),
          BlueButton('disconnect', () => disconnect()),
          BlueButton('is connected', () => isConnected()),
          BlueButton('ping server', () => pingServer()),
          BlueButton('ping user', () => pingUser()),
          BlueButton('get dialogs', () => getDialogs()),
          BlueButton('get dialogs count', () => getDialogsCount()),
          BlueButton('update dialog', () => updateDialog()),
          BlueButton('create dialog', () => createDialog()),
          BlueButton('delete dialog', () => deleteDialog()),
          BlueButton('leave dialog', () => leaveDialog()),
          BlueButton('is joined', () => isJoinedDialog()),
          BlueButton('join dialog', () => joinDialog()),
          BlueButton('get online users', () => getOnlineUsers()),
          BlueButton('send message', () => sendMessage()),
          BlueButton('send system message', () => sendSystemMessage()),
          BlueButton('subscribe message events', () {
            subscribeNewMessage();
            subscribeSystemMessage();
          }),
          BlueButton('unsubscribe message events', () {
            unsubscribeNewMessage();
            unsubscribeSystemMessage();
          }),
          BlueButton('mark message read', () => markMessageRead()),
          BlueButton('mark message delivered', () => markMessageDelivered()),
          BlueButton('subscribe message status', () {
            subscribeMessageDelivered();
            subscribeMessageRead();
          }),
          BlueButton('unsubscribe message status', () {
            unsubscribeDeliveredMessage();
            unsubscribeReadMessage();
          }),
          BlueButton('send is typing', () => sendIsTyping()),
          BlueButton('send stopped typing', () => sendStoppedTyping()),
          BlueButton('subscribe typing', () {
            subscribeUserTyping();
            subscribeUserStopTyping();
          }),
          BlueButton('unsubscribe typing', () {
            unsubscribeUserTyping();
            unsubscribeUserStopTyping();
          }),
          BlueButton('get dialog messages', () => getDialogMessages()),
          BlueButton('subscribe event connections', () {
            subscribeConnected();
            subscribeConnectionClosed();
            subscribeReconnectionFailed();
            subscribeReconnectionSuccess();
          }),
          BlueButton('unsubscribe event connections', () {
            unsubscribeConnected();
            unsubscribeConnectionClosed();
            unsubscribeReconnectionFailed();
            unsubscribeReconnectionSuccess();
          })
        ]))));
  }

  void connect() async {
    try {
      await QB.chat.connect(LOGGED_USER_ID, USER_PASSWORD);
      SnackBarUtils.showResult(_scaffoldKey, "The chat was connected");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void disconnect() async {
    try {
      await QB.chat.disconnect();
      SnackBarUtils.showResult(_scaffoldKey, "The chat was disconnected");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void isConnected() async {
    try {
      bool? connected = await QB.chat.isConnected();
      SnackBarUtils.showResult(_scaffoldKey, "The Chat connected: " + connected.toString());
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void pingServer() async {
    try {
      bool isPinged = await QB.chat.pingServer();
      SnackBarUtils.showResult(_scaffoldKey, "The server was pinged: $isPinged");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void pingUser() async {
    try {
      bool isPinged = await QB.chat.pingUser(OPPONENT_ID);
      SnackBarUtils.showResult(_scaffoldKey, "The user $OPPONENT_ID was pinged: $isPinged");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void getDialogs() async {
    try {
      QBSort sort = QBSort();
      sort.field = QBChatDialogSorts.LAST_MESSAGE_DATE_SENT;
      sort.ascending = true;

      QBFilter filter = QBFilter();
      filter.field = QBChatDialogFilterFields.LAST_MESSAGE_DATE_SENT;
      filter.operator = QBChatDialogFilterOperators.ALL;
      filter.value = "";

      List<QBDialog?> dialogs = await QB.chat.getDialogs();
      var dialogsLength = dialogs.length;
      SnackBarUtils.showResult(_scaffoldKey, "The $dialogsLength dialogs were loaded success");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void getDialogsCount() async {
    try {
      QBFilter filter = QBFilter();
      filter.field = QBChatDialogFilterFields.LAST_MESSAGE_DATE_SENT;
      filter.operator = QBChatDialogFilterOperators.ALL;
      filter.value = "";

      int limit = 100;
      int skip = 0;

      var dialogsCount = await QB.chat.getDialogsCount(qbFilter: filter, limit: limit, skip: skip);
      SnackBarUtils.showResult(_scaffoldKey, "The dialogs count is: $dialogsCount");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void updateDialog() async {
    try {
      String dialogName = "FLUTTER_CHAT_updated_dialog";
      List<int> addUsers = [];
      List<int> removeUsers = [];
      String dialogPhoto = "some photo url";

      QBDialog? updatedDialog = await QB.chat.updateDialog(_dialogId!,
          addUsers: addUsers, removeUsers: removeUsers, dialogName: dialogName, dialogPhoto: dialogPhoto);

      if (updatedDialog != null) {
        String? updatedDialogId = updatedDialog.id;
        SnackBarUtils.showResult(_scaffoldKey, "The dialog $updatedDialogId was updated");
      }
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void createDialog() async {
    List<int> occupantsIds = List.from(OPPONENTS_IDS);
    String dialogName = "FLUTTER_CHAT_" + DateTime.now().millisecond.toString();
    String dialogPhoto = "some photo url";

    int dialogType = QBChatDialogTypes.GROUP_CHAT;

    try {
      QBDialog? createdDialog = await QB.chat.createDialog(QBChatDialogTypes.GROUP_CHAT,
          occupantsIds: occupantsIds, dialogName: dialogName, dialogPhoto: dialogPhoto);

      if (createdDialog != null) {
        _dialogId = createdDialog.id!;
        SnackBarUtils.showResult(_scaffoldKey, "The dialog $_dialogId was created");
      }
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void deleteDialog() async {
    try {
      await QB.chat.deleteDialog(_dialogId!);
      SnackBarUtils.showResult(_scaffoldKey, "The dialog $_dialogId was deleted");
      _dialogId = null;
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void leaveDialog() async {
    try {
      await QB.chat.leaveDialog(_dialogId!);
      SnackBarUtils.showResult(_scaffoldKey, "The dialog $_dialogId was leaved");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void joinDialog() async {
    try {
      await QB.chat.joinDialog(_dialogId!);
      SnackBarUtils.showResult(_scaffoldKey, "The dialog $_dialogId was joined");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void isJoinedDialog() async {
    try {
      bool isJoined = await QB.chat.isJoinedDialog(_dialogId!);
      SnackBarUtils.showResult(_scaffoldKey, "The dialog is joined: $isJoined");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void getOnlineUsers() async {
    try {
      List<dynamic>? onlineUsers = await QB.chat.getOnlineUsers(_dialogId!);
      if (onlineUsers == null) {
        onlineUsers = [];
      }
      SnackBarUtils.showResult(_scaffoldKey, "The online users are: $onlineUsers");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void sendMessage() async {
    String messageBody = "Hello from flutter!" + "\n From user: " + LOGGED_USER_ID.toString();

    try {
      Map<String, String> properties = Map();
      properties["testProperty1"] = "testPropertyValue1";
      properties["testProperty2"] = "testPropertyValue2";
      properties["testProperty3"] = "testPropertyValue3";

      await QB.chat.sendMessage(_dialogId!, body: messageBody, saveToHistory: true, properties: properties);
      SnackBarUtils.showResult(_scaffoldKey, "The message was sent to dialog: $_dialogId");
    } on PlatformException catch (e) {
      PlatformException exception = PlatformException(code: "ERROR send message $e", message: "Error sending message");
      DialogUtils.showError(context, exception);
    }
  }

  void sendSystemMessage() async {
    try {
      await QB.chat.sendSystemMessage(OPPONENT_ID);
      SnackBarUtils.showResult(_scaffoldKey, "The system message was sent");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeNewMessage() async {
    if (_newMessageSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription for: " + QBChatEvents.RECEIVED_NEW_MESSAGE);
      return;
    }

    try {
      _newMessageSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.RECEIVED_NEW_MESSAGE, (data) {
        Map<dynamic, dynamic> map = Map<dynamic, dynamic>.from(data);

        Map<dynamic, dynamic> payload = Map<dynamic, dynamic>.from(map["payload"]);
        _messageId = payload["id"] as String;

        SnackBarUtils.showResult(_scaffoldKey, "Received message: \n ${payload["body"]}");
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.RECEIVED_NEW_MESSAGE);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeSystemMessage() async {
    if (_systemMessageSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription for: " + QBChatEvents.RECEIVED_SYSTEM_MESSAGE);
      return;
    }

    try {
      _systemMessageSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.RECEIVED_SYSTEM_MESSAGE, (data) {
        Map<dynamic, dynamic> map = Map<dynamic, dynamic>.from(data);

        Map<dynamic, dynamic> payload = Map<dynamic, dynamic>.from(map["payload"]);

        _messageId = payload["id"];

        SnackBarUtils.showResult(_scaffoldKey, "Received system message");
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.RECEIVED_SYSTEM_MESSAGE);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void markMessageRead() async {
    QBMessage qbMessage = QBMessage();
    qbMessage.dialogId = _dialogId;
    qbMessage.id = _messageId;
    qbMessage.senderId = LOGGED_USER_ID;

    try {
      await QB.chat.markMessageRead(qbMessage);
      SnackBarUtils.showResult(_scaffoldKey, "The message " + _messageId! + " was marked read");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void markMessageDelivered() async {
    QBMessage qbMessage = QBMessage();
    qbMessage.dialogId = _dialogId;
    qbMessage.id = _messageId;
    qbMessage.senderId = LOGGED_USER_ID;

    try {
      await QB.chat.markMessageDelivered(qbMessage);
      SnackBarUtils.showResult(_scaffoldKey, "The message " + _messageId! + " was marked delivered");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeMessageDelivered() async {
    if (_deliveredMessageSubscription != null) {
      SnackBarUtils.showResult(_scaffoldKey, "You already have a subscription for: " + QBChatEvents.MESSAGE_DELIVERED);
      return;
    }

    try {
      _deliveredMessageSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.MESSAGE_DELIVERED, (data) {
        LinkedHashMap<dynamic, dynamic> messageStatusHashMap = data;
        Map<dynamic, dynamic> messageStatusMap = Map<dynamic, dynamic>.from(messageStatusHashMap);
        Map<dynamic, dynamic> payloadMap = Map<dynamic, dynamic>.from(messageStatusHashMap["payload"]);

        String messageId = payloadMap["messageId"];
        int userId = payloadMap["userId"];
        String statusType = messageStatusMap["type"];

        SnackBarUtils.showResult(
            _scaffoldKey,
            "Received message status: $statusType \n From userId: $userId "
            "\n messageId: $messageId");
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.MESSAGE_DELIVERED);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeMessageRead() async {
    if (_readMessageSubscription != null) {
      SnackBarUtils.showResult(_scaffoldKey, "You already have a subscription for: " + QBChatEvents.MESSAGE_READ);
      return;
    }

    try {
      _readMessageSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.MESSAGE_READ, (data) {
        LinkedHashMap<dynamic, dynamic> messageStatusHashMap = data;
        Map<dynamic, dynamic> messageStatusMap = Map<dynamic, dynamic>.from(messageStatusHashMap);
        Map<dynamic, dynamic> payloadMap = Map<dynamic, dynamic>.from(messageStatusHashMap["payload"]);

        String messageId = payloadMap["messageId"];
        int userId = payloadMap["userId"];
        String statusType = messageStatusMap["type"];

        SnackBarUtils.showResult(
            _scaffoldKey,
            "Received message status: $statusType \n From userId: $userId "
            "\n messageId: $messageId");
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.MESSAGE_READ);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void sendIsTyping() async {
    try {
      await QB.chat.sendIsTyping(_dialogId!);
      SnackBarUtils.showResult(_scaffoldKey, "Sent is typing for dialog: " + _dialogId!);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void sendStoppedTyping() async {
    try {
      await QB.chat.sendStoppedTyping(_dialogId!);
      SnackBarUtils.showResult(_scaffoldKey, "Sent stopped typing for dialog: " + _dialogId!);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeUserTyping() async {
    if (_userTypingSubscription != null) {
      SnackBarUtils.showResult(_scaffoldKey, "You already have a subscription for: " + QBChatEvents.USER_IS_TYPING);
      return;
    }

    try {
      _userTypingSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.USER_IS_TYPING, (data) {
        Map<dynamic, dynamic> map = Map<String, dynamic>.from(data);
        Map<dynamic, dynamic> payload = Map<String, dynamic>.from(map["payload"]);
        int userId = payload["userId"];
        SnackBarUtils.showResult(_scaffoldKey, "Typing user: " + userId.toString());
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.USER_IS_TYPING);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeUserStopTyping() async {
    if (_userStopTypingSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription for: " + QBChatEvents.USER_STOPPED_TYPING);
      return;
    }

    try {
      _userStopTypingSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.USER_STOPPED_TYPING, (data) {
        Map<dynamic, dynamic> map = Map<String, dynamic>.from(data);
        Map<dynamic, dynamic> payload = Map<String, dynamic>.from(map["payload"]);
        int userId = payload["userId"];
        SnackBarUtils.showResult(_scaffoldKey, "Stopped typing user: " + userId.toString());
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.USER_STOPPED_TYPING);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void getDialogMessages() async {
    try {
      List<QBMessage?> messages = await QB.chat.getDialogMessages(_dialogId!);
      int countMessages = messages.length;

      if (countMessages > 0) {
        _messageId = messages[0]!.id;
      }

      SnackBarUtils.showResult(_scaffoldKey, "Loaded messages: " + countMessages.toString());
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeConnected() async {
    if (_connectedSubscription != null) {
      SnackBarUtils.showResult(_scaffoldKey, "You already have a subscription for: " + QBChatEvents.CONNECTED);
      return;
    }

    try {
      _connectedSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.CONNECTED, (data) {
        SnackBarUtils.showResult(_scaffoldKey, "Received: " + QBChatEvents.CONNECTED);
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.CONNECTED);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeConnectionClosed() async {
    if (_connectionClosedSubscription != null) {
      SnackBarUtils.showResult(_scaffoldKey, "You already have a subscription for: " + QBChatEvents.CONNECTION_CLOSED);
      return;
    }

    try {
      _connectionClosedSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.CONNECTION_CLOSED, (data) {
        SnackBarUtils.showResult(_scaffoldKey, "Received: " + QBChatEvents.CONNECTION_CLOSED);
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.CONNECTION_CLOSED);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeReconnectionFailed() async {
    if (_reconnectionFailedSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription for: " + QBChatEvents.RECONNECTION_FAILED);
      return;
    }

    try {
      _reconnectionFailedSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.RECONNECTION_FAILED, (data) {
        SnackBarUtils.showResult(_scaffoldKey, "Received: " + QBChatEvents.RECONNECTION_FAILED);
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.RECONNECTION_FAILED);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void subscribeReconnectionSuccess() async {
    if (_reconnectionSuccessSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription for: " + QBChatEvents.RECONNECTION_SUCCESSFUL);
      return;
    }

    try {
      _reconnectionSuccessSubscription = await QB.chat.subscribeChatEvent(QBChatEvents.RECONNECTION_SUCCESSFUL, (data) {
        SnackBarUtils.showResult(_scaffoldKey, "Received: " + QBChatEvents.RECONNECTION_SUCCESSFUL);
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed: " + QBChatEvents.RECONNECTION_SUCCESSFUL);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void unsubscribeNewMessage() {
    _newMessageSubscription?.cancel();
    _newMessageSubscription = null;
  }

  void unsubscribeSystemMessage() {
    _systemMessageSubscription?.cancel();
    _systemMessageSubscription = null;
  }

  void unsubscribeDeliveredMessage() async {
    _deliveredMessageSubscription?.cancel();
    _deliveredMessageSubscription = null;
  }

  void unsubscribeReadMessage() async {
    _readMessageSubscription?.cancel();
    _readMessageSubscription = null;
  }

  void unsubscribeUserTyping() async {
    _userTypingSubscription?.cancel();
    _userTypingSubscription = null;
  }

  void unsubscribeUserStopTyping() async {
    _userStopTypingSubscription?.cancel();
    _userStopTypingSubscription = null;
  }

  void unsubscribeConnected() {
    _connectedSubscription?.cancel();
    _connectedSubscription = null;
  }

  void unsubscribeConnectionClosed() {
    _connectionClosedSubscription?.cancel();
    _connectionClosedSubscription = null;
  }

  void unsubscribeReconnectionFailed() {
    _reconnectionFailedSubscription?.cancel();
    _reconnectionFailedSubscription = null;
  }

  void unsubscribeReconnectionSuccess() {
    _reconnectionSuccessSubscription?.cancel();
    _reconnectionSuccessSubscription = null;
  }
}
