import 'package:chat_sample/data/auth_repository.dart';
import 'package:chat_sample/data/storage_repository.dart';
import 'package:chat_sample/data/users_repository.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/auth/module.dart';
import 'package:quickblox_sdk/models/qb_user.dart';

import '../../main.dart';
import '../base_bloc.dart';
import 'login_screen_events.dart';
import 'login_screen_states.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class LoginScreenBloc extends Bloc<LoginScreenEvents, LoginScreenStates, void> {
  static const MIN_LENGTH = 3;
  static const MAX_LENGTH_USER_NAME = 20;
  static const MAX_LENGTH_LOGIN = 50;

  String _login = "";
  String _userName = "";

  final AuthRepository _authRepository = AuthRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final StorageRepository _storageRepository = StorageRepository();

  @override
  void init() {
    super.init();
    states?.add(LoginFieldInvalidState());
    states?.add(UserNameFieldInvalidState());
  }

  @override
  void onReceiveEvent(LoginScreenEvents receivedEvent) {
    if (receivedEvent is LoginPressedEvent) {
      states?.add(LoginInProgressState());
      _handleLogin();
    }
    if (receivedEvent is ChangedLoginFieldEvent) {
      _login = receivedEvent.login;
      _handleLoginField();
    }
    if (receivedEvent is ChangedUsernameFieldEvent) {
      this._userName = receivedEvent.userName;
      _handleUserNameField();
    }
  }

  void _handleLogin() {
    if (_allowLogin()) {
      states?.add(LoginInProgressState());
      _loginQB();
    }
  }

  void _handleLoginField() {
    if (_validLogin()) {
      states?.add(LoginFieldValidState());
    } else {
      states?.add(LoginFieldInvalidState());
    }
    if (_allowLogin()) {
      states?.add(AllowLoginState());
    }
  }

  void _handleUserNameField() {
    if (_validUserName()) {
      states?.add(UserNameFieldValidState());
    } else {
      states?.add(UserNameFieldInvalidState());
    }
    if (_allowLogin()) {
      states?.add(AllowLoginState());
    }
  }

  bool _allowLogin() {
    return _validLogin() && _validUserName();
  }

  bool _validLogin() {
    if (_login.isEmpty || _login.length < MIN_LENGTH || _login.length > MAX_LENGTH_LOGIN) {
      return false;
    }
    int min = MIN_LENGTH - 1;
    int max = MAX_LENGTH_LOGIN - 1;
    bool validLogin = RegExp('^[a-zA-Z][a-zA-Z0-9]{$min,$max}\$').hasMatch(_login);
    bool validEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_login);
    return validLogin || validEmail;
  }

  bool _validUserName() {
    if (_userName.isEmpty ||
        _userName.length < MIN_LENGTH ||
        _userName.length > MAX_LENGTH_USER_NAME) {
      return false;
    }
    int min = MIN_LENGTH - 1;
    int max = MAX_LENGTH_USER_NAME - 1;
    bool validUserName = RegExp('^[a-zA-Z][a-zA-Z 0-9]{$min,$max}\$').hasMatch(_userName);
    return validUserName;
  }

  void _loginQB() async {
    _login = _login.trim();
    _userName = _userName.trim();
    try {
      QBLoginResult qbLoginResult = await _authRepository.login(_login, DEFAULT_USER_PASSWORD);
      if (qbLoginResult.qbUser?.id != null) {
        _storageRepository.saveUserId(qbLoginResult.qbUser!.id!);
        _storageRepository.saveUserLogin(_login);
        _storageRepository.saveUserFullName(_userName);
        _storageRepository.saveUserPassword(DEFAULT_USER_PASSWORD);

        if (qbLoginResult.qbUser!.fullName != _userName) {
          _updateUser();
        } else {
          states?.add(LoginSuccessState(qbLoginResult.qbUser!));
        }
      } else {
        states?.add(LoginErrorState("User is null"));
      }
    } on PlatformException catch (e) {
      if (e.code == "Unauthorized" || e.code.contains('401')) {
        _createUser();
      } else {
        states?.add(LoginErrorState(makeErrorMessage(e)));
      }
    }
  }

  void _createUser() async {
    try {
      QBUser? user = await _usersRepository.createUser(_login, _userName, DEFAULT_USER_PASSWORD);
      if (user != null) {
        _loginQB();
      } else {
        states?.add(LoginErrorState("Error creating user"));
      }
    } on PlatformException catch (e) {
      states?.add(LoginErrorState(makeErrorMessage(e)));
    }
  }

  void _updateUser() async {
    try {
      QBUser? user = await _usersRepository.updateUser(_login, _userName);
      if (user != null) {
        states?.add(LoginSuccessState(user));
      } else {
        states?.add(LoginErrorState("Error updating user"));
      }
    } on PlatformException catch (e) {
      states?.add(LoginErrorState(makeErrorMessage(e)));
    }
  }
}
