import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_subscription.dart';
import 'package:quickblox_sdk/push/constants.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';

class SubscriptionsScreen extends StatefulWidget {
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
        appBar: _buildAppBar(),
        body: Center(
            child: Column(children: [
          _buildButton('create push subscription', () => createPushSubscription()),
          _buildButton('get push subscriptions', () => getPushSubscriptions()),
          _buildButton('remove push subscription', () => removePushSubscription())
        ])));
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        title: const Text('Subscriptions'),
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
