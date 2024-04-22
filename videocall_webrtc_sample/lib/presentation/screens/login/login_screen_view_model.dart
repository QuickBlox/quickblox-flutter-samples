import 'package:flutter/services.dart';
import 'package:quickblox_sdk/auth/module.dart';
import 'package:videocall_webrtc_sample/dependency/dependency_impl.dart';
import 'package:videocall_webrtc_sample/managers/auth_manager.dart';
import 'package:videocall_webrtc_sample/managers/storage_manager.dart';
import 'package:videocall_webrtc_sample/presentation/base_view_model.dart';
import 'package:videocall_webrtc_sample/presentation/utils/error_parser.dart';

class LoginScreenViewModel extends BaseViewModel {
  static const MIN_LENGTH = 3;
  static const MAX_LENGTH_LOGIN = 50;

  final AuthManager _authManager = DependencyImpl.getInstance().getAuthManager();
  final StorageManager _storageManager = DependencyImpl.getInstance().getStorageManager();

  bool isLoggedIn = false;
  bool isLoginError = false;
  bool isPasswordError = false;

  Future<void> login(String userLogin, String userPassword) async {
    try {
      hideError();
      isLoggedIn = false;
      showLoading();
      QBLoginResult qbLoginResult = await _authManager.login(userLogin, userPassword);

      if (qbLoginResult.qbUser?.id != null) {
        _storageManager.saveUserId(qbLoginResult.qbUser!.id!);
        _storageManager.saveUserLogin(userLogin);
        String? name = qbLoginResult.qbUser?.fullName ?? qbLoginResult.qbUser?.login;
        _storageManager.saveUserName(name!);
        _storageManager.saveUserPassword(userPassword);
      }
      isLoggedIn = true;
      hideLoading();
    } on PlatformException catch (e) {
      hideLoading();
      showError(ErrorParser.parseFrom(e));
    }
  }

  bool isValidCredentials(String login, String password) {
    isLoginError = false;
    isPasswordError = false;
    final isValidLogin = _validLogin(login);
    final isValidPassword = _validPassword(password);

    if (!isValidLogin) {
      isLoginError = true;
    }
    if (!isValidPassword) {
      isPasswordError = true;
    }
    notifyListeners();
    return isValidLogin && isValidPassword;
  }

  bool _validLogin(String login) {
    if (login.isEmpty || login.length < MIN_LENGTH || login.length > MAX_LENGTH_LOGIN) {
      return false;
    }
    int min = MIN_LENGTH - 1;
    int max = MAX_LENGTH_LOGIN - 1;
    bool validLogin = RegExp('^[a-zA-Z][a-zA-Z0-9]{$min,$max}\$').hasMatch(login);
    bool validEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(login);
    return validLogin || validEmail;
  }

  bool _validPassword(String password) {
    if (password.isEmpty) {
      return false;
    }
    return true;
  }
}
