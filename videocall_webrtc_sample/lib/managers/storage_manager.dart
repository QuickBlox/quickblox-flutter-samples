import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

class StorageManager {
  static const int _NOT_SAVED_USER_ID = -1;
  static const String _USER_ID_KEY = "user_id_key";
  static const String _USER_LOGIN_KEY = "user_login_key";
  static const String _USER_NAME_KEY = "user_name_key";
  static const String _USER_PASSWORD_KEY = "user_password_key";

   Box<dynamic>? _hiveBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _hiveBox = await Hive.openBox("storage");
  }

  Future<int> getLoggedUserId() async {
    return await _hiveBox?.get(_USER_ID_KEY) ?? _NOT_SAVED_USER_ID;
  }

  Future<String> getUserLogin() async {
    return await _hiveBox?.get(_USER_LOGIN_KEY, defaultValue: "");
  }

  Future<String> getNameLogin() async {
    return await _hiveBox?.get(_USER_NAME_KEY, defaultValue: "");
  }

  Future<String> getUserPassword() async {
    return await _hiveBox?.get(_USER_PASSWORD_KEY, defaultValue: "");
  }

  Future<void> saveUserId(int userId) async {
    await _hiveBox?.put(_USER_ID_KEY, userId);
  }

  Future<void> saveUserLogin(String login) async {
    await _hiveBox?.put(_USER_LOGIN_KEY, login);
  }

  Future<void> saveUserName(String login) async {
    await _hiveBox?.put(_USER_NAME_KEY, login);
  }

  Future<void> saveUserPassword(String password) async {
    await _hiveBox?.put(_USER_PASSWORD_KEY, password);
  }

  Future<bool> isExistSavedUser() async {
    int userId = await _hiveBox?.get(_USER_ID_KEY) ?? _NOT_SAVED_USER_ID;

    return userId > _NOT_SAVED_USER_ID;
  }

  Future<void> cleanCredentials() async {
    await _hiveBox?.clear();
  }
}
