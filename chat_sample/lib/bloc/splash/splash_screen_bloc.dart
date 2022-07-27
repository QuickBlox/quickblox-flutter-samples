import 'dart:async';

import 'package:chat_sample/bloc/splash/splash_screen_events.dart';
import 'package:chat_sample/bloc/splash/splash_screen_states.dart';
import 'package:chat_sample/data/auth_repository.dart';
import 'package:chat_sample/data/settings_repository.dart';
import 'package:chat_sample/data/storage_repository.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/auth/module.dart';

import '../../main.dart';
import '../base_bloc.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class SplashScreenBloc extends Bloc<SplashScreenEvents, SplashScreenStates, void> {
  static const int DELAY_SECONDS = 3;

  final SettingsRepository _settingsRepository = SettingsRepository();
  final AuthRepository _authRepository = AuthRepository();
  final StorageRepository _storageRepository = StorageRepository();

  @override
  void onReceiveEvent(SplashScreenEvents event) {
    if (event is AuthEvent) {
      Timer(Duration(seconds: DELAY_SECONDS), () {
        _setSettings();
      });
    }
  }

  Future<void> _setSettings() async {
    try {
      await _settingsRepository.init(APPLICATION_ID, AUTH_KEY, AUTH_SECRET, ACCOUNT_KEY);
      await _settingsRepository.initStreamManagement(true, 5);
      // for testing
      await _settingsRepository.enableXMPPLogging();
      await _settingsRepository.enableLogging();

      _initSavedUser();
    } on PlatformException catch (e) {
      states?.add(AuthenticationErrorState(makeErrorMessage(e)));
    }
  }

  void _initSavedUser() async {
    int userId = await _storageRepository.getUserId();
    if (userId != StorageRepository.NOT_SAVED_USER_ID) {
      states?.add(LoginInProgressState());
      _login();
    } else {
      states?.add(NeedLoginState());
    }
  }

  void _login() async {
    try {
      String userLogin = await _storageRepository.getUserLogin();
      String userPassword = await _storageRepository.getUserPassword();
      QBLoginResult qbLoginResult = await _authRepository.login(userLogin, userPassword);
      if (qbLoginResult.qbUser?.id != null) {
        _storageRepository.saveUserId(qbLoginResult.qbUser!.id!);
        states?.add(LoginSuccessState());
      } else {
        states?.add(NeedLoginState());
      }
    } on PlatformException catch (e) {
      states?.add(AuthenticationErrorState(makeErrorMessage(e)));
    }
  }
}
