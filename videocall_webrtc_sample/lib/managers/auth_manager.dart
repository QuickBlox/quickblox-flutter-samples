import 'package:quickblox_sdk/auth/module.dart';
import 'package:quickblox_sdk/models/qb_session.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

class AuthManager {
  Future<QBLoginResult> login(String login, String password) async {
    return await QB.auth.login(login, password);
  }

  Future<void> logout() async {
    await QB.auth.logout();
  }

  Future<QBSession?> createSession(QBSession qbSession) async {
    return QB.auth.setSession(qbSession);
  }

  Future<QBSession?> getSession() async {
    return QB.auth.getSession();
  }

  Future<bool> isSessionExist() async {
    QBSession? session = await QB.auth.getSession();
    if (session == null) {
      return false;
    } else {
      return true;
    }
  }

}
