/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class SplashScreenStates {}

class AuthenticationErrorState extends SplashScreenStates {
  final String error;

  AuthenticationErrorState(this.error);
}

class NeedLoginState extends SplashScreenStates {}

class LoginSuccessState extends SplashScreenStates {}

class LoginInProgressState extends SplashScreenStates {}
