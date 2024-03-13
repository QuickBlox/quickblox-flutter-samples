import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_event.dart';
import 'package:quickblox_sdk/notifications/constants.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/credentials.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';
import 'package:quickblox_sdk_example/widgets/blue_app_bar.dart';
import 'package:quickblox_sdk_example/widgets/blue_button.dart';

class EventsScreen extends StatefulWidget {
  static show(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => EventsScreen()));
  }

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
        appBar: BlueAppBar('Events'),
        body: Center(
            child: Column(children: [
          BlueButton('create notification', () => createNotification()),
          BlueButton('update notification', () => updateNotification()),
          BlueButton('remove notification', () => removeNotification()),
          BlueButton('get by id notification', () => getByIdNotification()),
          BlueButton('get notifications', () => getNotifications())
        ])));
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
