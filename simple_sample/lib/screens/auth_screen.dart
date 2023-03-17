import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/auth/constants.dart';
import 'package:quickblox_sdk/auth/module.dart';
import 'package:quickblox_sdk/models/qb_session.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/credentials.dart';
import 'package:quickblox_sdk_example/data_holder.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';

class AuthScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _sessionExpiredSubscription;

  @override
  void dispose() {
    super.dispose();
    _unsubscribeSessionExpired();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        body: Center(
            child: Column(children: [
          _buildButton('login', () => login()),
          _buildButton('logout', () => logout()),
          _buildButton('set session', () => setSession()),
          _buildButton('get session', () => getSession()),
          _buildButton('subscribe session expired', () => _subscribeSessionExpired()),
          _buildButton('unsubscribe session expired', () => _unsubscribeSessionExpired())
        ])));
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        title: const Text('Auth'),
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

  Future<void> login() async {
    try {
      QBLoginResult result = await QB.auth.login(USER_LOGIN, USER_PASSWORD);

      QBUser? qbUser = result.qbUser;
      QBSession? qbSession = result.qbSession;

      qbSession!.applicationId = int.parse(APP_ID);

      DataHolder.getInstance().setSession(qbSession);
      DataHolder.getInstance().setUser(qbUser);

      SnackBarUtils.showResult(_scaffoldKey, "Login success");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> logout() async {
    try {
      await QB.auth.logout();
      SnackBarUtils.showResult(_scaffoldKey, "Logout success");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> setSession() async {
    try {
      QBSession? savedSession = DataHolder.getInstance().getSession();

      if (savedSession == null) {
        DialogUtils.showError(context, PlatformException(code: "the session is null"));
        return;
      }

      QBSession? session = await QB.auth.setSession(savedSession);
      if (session != null) {
        DataHolder.getInstance().setSession(session);
        SnackBarUtils.showResult(_scaffoldKey, "Set session success");
      } else {
        DialogUtils.showError(context, PlatformException(code: "The session is null"));
      }
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getSession() async {
    try {
      QBSession? session = await QB.auth.getSession();
      if (session != null) {
        DataHolder.getInstance().setSession(session);
        SnackBarUtils.showResult(_scaffoldKey, "Get session success");
      } else {
        DialogUtils.showError(context, PlatformException(message: "The session is null", code: ""));
      }
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> _subscribeSessionExpired() async {
    if (_sessionExpiredSubscription != null) {
      SnackBarUtils.showResult(_scaffoldKey, "You already have a subscription for: " + QBAuthEvents.SESSION_EXPIRED);
      return;
    }

    try {
      _sessionExpiredSubscription = await QB.auth.subscribeAuthEvent(QBAuthEvents.SESSION_EXPIRED, (data) {
        DialogUtils.showError(context, PlatformException(message: "The session expired", code: ""));
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscribed");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> _unsubscribeSessionExpired() async {
    _sessionExpiredSubscription?.cancel();
    _sessionExpiredSubscription = null;
    SnackBarUtils.showResult(_scaffoldKey, "Unsubscribed");
  }
}
