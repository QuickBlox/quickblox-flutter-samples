import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class StorageRepository {
  static const int NOT_SAVED_USER_ID = -1;
  static const String USER_ID_KEY = "user_id_key";
  static const String USER_LOGIN_KEY = "user_login_key";
  static const String USER_FULL_NAME_KEY = "user_full_name_key";
  static const String USER_PASSWORD_KEY = "user_password_key";

  var _hiveBox = Hive.openBox("storage");

  void saveUserId(int userId) async {
    var box = await _hiveBox;
    box.put(USER_ID_KEY, userId);
  }

  Future<int> getUserId() async {
    var box = await _hiveBox;
    return box.get(USER_ID_KEY) ?? NOT_SAVED_USER_ID;
  }

  void saveUserLogin(String login) async {
    var box = await _hiveBox;
    box.put(USER_LOGIN_KEY, login);
  }

  Future<String> getUserLogin() async {
    var box = await _hiveBox;
    return box.get(USER_LOGIN_KEY, defaultValue: "");
  }

  void saveUserFullName(String fullName) async {
    var box = await _hiveBox;
    box.put(USER_FULL_NAME_KEY, fullName);
  }

  Future<String> getUserFullName() async {
    var box = await _hiveBox;
    return box.get(USER_FULL_NAME_KEY, defaultValue: "");
  }

  void saveUserPassword(String password) async {
    var box = await _hiveBox;
    box.put(USER_PASSWORD_KEY, password);
  }

  Future<String> getUserPassword() async {
    var box = await _hiveBox;
    return box.get(USER_PASSWORD_KEY, defaultValue: "");
  }

  void cleanCredentials() async {
    saveUserId(NOT_SAVED_USER_ID);
    saveUserLogin("");
    saveUserFullName("");
    saveUserPassword("");
  }
}
