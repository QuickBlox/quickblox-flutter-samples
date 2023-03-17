import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_settings.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/credentials.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        body: Center(
            child: Column(children: [
          _buildButton('init credentials', () => init()),
          _buildButton('get', () => getSettings()),
          _buildButton('enable carbon', () => _enableCarbons()),
          _buildButton('disable carbons', () => _disableCarbons()),
          _buildButton('init stream management', () => _initStreamManagement()),
          _buildButton('enable auto reconnect', () => _enableAutoReconnect()),
          _buildButton('enable logging', () => _enableLogging()),
          _buildButton('disable logging', () => _disableLogging())
        ])));
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        title: const Text('Settings'),
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
