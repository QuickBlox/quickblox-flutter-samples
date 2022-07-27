
/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class LoginScreenEvents {}

class LoginPressedEvent extends LoginScreenEvents {}

class ChangedLoginFieldEvent extends LoginScreenEvents {
  final String login;

  ChangedLoginFieldEvent(this.login);
}

class ChangedUsernameFieldEvent extends LoginScreenEvents {
  final String userName;

  ChangedUsernameFieldEvent(this.userName);
}
