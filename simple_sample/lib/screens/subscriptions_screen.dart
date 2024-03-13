import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_subscription.dart';
import 'package:quickblox_sdk/push/constants.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';
import 'package:quickblox_sdk_example/widgets/blue_app_bar.dart';
import 'package:quickblox_sdk_example/widgets/blue_button.dart';

class SubscriptionsScreen extends StatefulWidget {
  static show(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SubscriptionsScreen()));
  }

  @override
  State<StatefulWidget> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int? _id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: BlueAppBar('Subscriptions'),
        body: Center(
            child: Column(children: [
          BlueButton('create push subscription', () => createPushSubscription()),
          BlueButton('get push subscriptions', () => getPushSubscriptions()),
          BlueButton('remove push subscription', () => removePushSubscription())
        ])));
  }

  Future<void> createPushSubscription() async {
    String deviceToken = "test";

    try {
      List<QBSubscription?> subscriptions = await QB.subscriptions.create(deviceToken, QBPushChannelNames.GCM);
      int length = subscriptions.length;

      if (length > 0) {
        _id = subscriptions[0]!.id;
      }

      SnackBarUtils.showResult(_scaffoldKey, "Push was created with token: $deviceToken, subscription length $length");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getPushSubscriptions() async {
    try {
      List<QBSubscription?> subscriptions = await QB.subscriptions.get();
      int count = subscriptions.length;
      SnackBarUtils.showResult(_scaffoldKey, "Push Subscriptions were loaded: $count");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> removePushSubscription() async {
    try {
      await QB.subscriptions.remove(_id!);
      SnackBarUtils.showResult(_scaffoldKey, "Push subcription with id: $_id was removed");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }
}
