import 'package:quickblox_sdk/auth/module.dart';
import 'package:quickblox_sdk/models/qb_session.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class AuthRepository {
  Future<QBLoginResult> login(String login, String password) async {
    return QB.auth.login(login, password);
  }

  Future<void> logout() async {
    await QB.auth.logout();
  }

  Future<QBSession> createSession(QBSession qbSession) async {
    return QB.auth.setSession(qbSession) as QBSession;
  }

  Future<QBSession> getSession() async {
    return QB.auth.getSession() as QBSession;
  }
}
