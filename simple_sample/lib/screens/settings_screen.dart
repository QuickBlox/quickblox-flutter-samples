import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_settings.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/credentials.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';
import 'package:quickblox_sdk_example/widgets/blue_app_bar.dart';
import 'package:quickblox_sdk_example/widgets/blue_button.dart';

class SettingsScreen extends StatefulWidget {
  static show(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SettingsScreen()));
  }

  @override
  State<StatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: BlueAppBar('Settings'),
        body: Center(
            child: Column(children: [
          BlueButton('init credentials', () => init()),
          BlueButton('get', () => getSettings()),
          BlueButton('enable carbon', () => _enableCarbons()),
          BlueButton('disable carbons', () => _disableCarbons()),
          BlueButton('init stream management', () => _initStreamManagement()),
          BlueButton('enable auto reconnect', () => _enableAutoReconnect()),
          BlueButton('enable logging', () => _enableLogging()),
          BlueButton('disable logging', () => _disableLogging())
        ])));
  }

  Future<void> init() async {
    try {
      await QB.settings
          .init(APP_ID, AUTH_KEY, AUTH_SECRET, ACCOUNT_KEY, apiEndpoint: API_ENDPOINT, chatEndpoint: CHAT_ENDPOINT);
      SnackBarUtils.showResult(_scaffoldKey, "The credentials were set");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getSettings() async {
    try {
      QBSettings? settings = await QB.settings.get();
      SnackBarUtils.showResult(_scaffoldKey, "The settings were loaded");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> _enableCarbons() async {
    try {
      await QB.settings.enableCarbons();
      SnackBarUtils.showResult(_scaffoldKey, "Carbon was enabled");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> _disableCarbons() async {
    try {
      await QB.settings.disableCarbons();
      SnackBarUtils.showResult(_scaffoldKey, "Carbon was disabled");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> _initStreamManagement() async {
    bool autoReconnect = true;
    int MESSAGE_TIMEOUT = 3;
    try {
      await QB.settings.initStreamManagement(MESSAGE_TIMEOUT, autoReconnect: autoReconnect);
      SnackBarUtils.showResult(_scaffoldKey, "Stream management was initiated with timeout $MESSAGE_TIMEOUT");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> _enableAutoReconnect() async {
    try {
      await QB.settings.enableAutoReconnect(true);
      SnackBarUtils.showResult(_scaffoldKey, "Auto reconnect was enabled");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> _enableLogging() async {
    QB.settings.enableLogging();
    QB.settings.enableXMPPLogging();
    SnackBarUtils.showResult(_scaffoldKey, "Logging were enabled");
  }

  Future<void> _disableLogging() async {
    QB.settings.disableLogging();
    QB.settings.disableXMPPLogging();
    SnackBarUtils.showResult(_scaffoldKey, "Logging were disabled");
  }
}
