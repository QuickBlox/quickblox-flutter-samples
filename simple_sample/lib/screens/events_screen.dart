import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_event.dart';
import 'package:quickblox_sdk/notifications/constants.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/credentials.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';

class EventsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int? _id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        body: Center(
            child: Column(children: [
          _buildButton('create notification', () => createNotification()),
          _buildButton('update notification', () => updateNotification()),
          _buildButton('remove notification', () => removeNotification()),
          _buildButton('get by id notification', () => getByIdNotification()),
          _buildButton('get notifications', () => getNotifications())
        ])));
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        title: const Text('Events'),
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()));
  }

  Widget _buildButton(String title, Function? callback) {
    return MaterialButton(
        minWidth: 200,
        child: Text(title),
        color: Theme.of(context).primaryColor,
        textColor: Colors.white,
        onPressed: () => callback?.call());
  }

  Future<void> createNotification() async {
    String type = QBNotificationEventTypes.ONE_SHOT;
    String notificationEventType = QBNotificationTypes.PUSH;
    int senderId = LOGGED_USER_ID;

    Map<String, Object> payload = Map();
    payload["message"] = "test";

    try {
      List<QBEvent?> qbEventsList = await QB.events.create(type, notificationEventType, senderId, payload);

      for (int i = 0; i < qbEventsList.length; i++) {
        QBEvent? event = qbEventsList[i];
        int? notificationId = event!.id;
        _id = event.id!;
        SnackBarUtils.showResult(_scaffoldKey, "The Notification was created with id: $notificationId");
      }
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> updateNotification() async {
    try {
      QBEvent? qbEvent = await QB.events.update(_id!, name: "test");
      int? notificationId = qbEvent!.id;
      SnackBarUtils.showResult(_scaffoldKey, "The Notification with id: $notificationId was updated");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> removeNotification() async {
    try {
      await QB.events.remove(_id!);
      SnackBarUtils.showResult(_scaffoldKey, "The notification with id: $_id was removed");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getByIdNotification() async {
    try {
      QBEvent? qbEvent = await QB.events.getById(_id!);
      int? notificationId = qbEvent!.id;
      SnackBarUtils.showResult(_scaffoldKey, "The notification with id: $notificationId was loaded");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getNotifications() async {
    try {
      List<QBEvent?> qbEventsList = await QB.events.get();
      int count = qbEventsList.length;
      SnackBarUtils.showResult(_scaffoldKey, "Notifications were loaded. Count is: $count");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }
}
