import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Auth'),
          centerTitle: true,
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop()),
        ),
        body: Center(
            child: Column(children: [
          MaterialButton(
            minWidth: 200,
            child: Text('login'),
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
            onPressed: login,
          ),
          MaterialButton(
            minWidth: 200,
            child: Text('logout'),
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
            onPressed: logout,
          ),
          MaterialButton(
            minWidth: 200,
            child: Text('set session'),
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
            onPressed: setSession,
          ),
          MaterialButton(
            minWidth: 200,
            child: Text('get session'),
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
            onPressed: getSession,
          ),
        ])));
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
        DialogUtils.showError(
            context, PlatformException(code: "the session is null"));
        return;
      }

      QBSession? session = await QB.auth.setSession(savedSession);
      if (session != null) {
        DataHolder.getInstance().setSession(session);
        SnackBarUtils.showResult(_scaffoldKey, "Set session success");
      } else {
        DialogUtils.showError(
            context, PlatformException(code: "The session is null"));
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
        DialogUtils.showError(context,
            PlatformException(message: "The session is null", code: ""));
      }
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }
}
