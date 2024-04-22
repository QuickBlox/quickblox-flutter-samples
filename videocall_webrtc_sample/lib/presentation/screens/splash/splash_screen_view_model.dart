import 'package:flutter/services.dart';
import 'package:quickblox_sdk/auth/module.dart';
import 'package:videocall_webrtc_sample/dependency/dependency_impl.dart';
import 'package:videocall_webrtc_sample/main.dart';
import 'package:videocall_webrtc_sample/managers/auth_manager.dart';
import 'package:videocall_webrtc_sample/managers/storage_manager.dart';
import 'package:videocall_webrtc_sample/presentation/base_view_model.dart';

import '../../../managers/settings_manager.dart';
import '../../utils/error_parser.dart';

class SplashScreenViewModel extends BaseViewModel {
  final SettingsManager _settingsManager = DependencyImpl.getInstance().getSettingsManager();
  final StorageManager _storageManager = DependencyImpl.getInstance().getStorageManager();
  final AuthManager _authManager = DependencyImpl.getInstance().getAuthManager();

  bool isLoggedIn = false;

  Future<void> initQBSDK() async {
    try {
      await _settingsManager.init(APPLICATION_ID, AUTH_KEY, AUTH_SECRET, ACCOUNT_KEY);

      String url = ICE_SEVER_URL;
      if (url.isNotEmpty) {
        String userName = ICE_SERVER_USER;
        String password = ICE_SERVER_PASSWORD;
        await _settingsManager.setIceServers(url, userName, password);
      }
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> enableLogging() async {
    try {
      await _settingsManager.enableXMPPLogging();
      await _settingsManager.enableLogging();
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> checkSavedUserAndLogin() async {
    try {
      showLoading();

      bool isExistSavedUser = await _storageManager.isExistSavedUser();
      if (isExistSavedUser) {
        String userLogin = await _storageManager.getUserLogin();
        String userPassword = await _storageManager.getUserPassword();
        await _login(userLogin, userPassword);
      }

      hideLoading();
    } on PlatformException catch (e) {
      hideLoading();
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> _login(String userLogin, String userPassword) async {
    QBLoginResult qbLoginResult = await _authManager.login(userLogin, userPassword);
    if (qbLoginResult.qbUser?.id != null) {
      _storageManager.saveUserId(qbLoginResult.qbUser!.id!);
      isLoggedIn = true;
    } else {
      isLoggedIn = false;
    }
  }
}
