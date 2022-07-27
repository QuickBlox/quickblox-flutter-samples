import 'package:chat_sample/models/user_wrapper.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class SelectUsersScreenStates {}

class ChangedSelectedUsersState extends SelectUsersScreenStates {
  final List<int> usersIds;

  ChangedSelectedUsersState(this.usersIds);
}

class LoadUsersInProgressState extends SelectUsersScreenStates {}

class LoadNextUsersInProgressState extends SelectUsersScreenStates {}

class ErrorState extends SelectUsersScreenStates {
  final String error;

  ErrorState(this.error);
}

class LoadUsersSuccessState extends SelectUsersScreenStates {
  final List<QBUserWrapper> users;

  LoadUsersSuccessState(this.users);
}

class CreatedDialogState extends SelectUsersScreenStates {
  final String dialogId;

  CreatedDialogState(this.dialogId);
}

class CreatingDialogState extends SelectUsersScreenStates {}

class CreateDialogErrorState extends SelectUsersScreenStates {
  final String error;

  CreateDialogErrorState(this.error);
}
