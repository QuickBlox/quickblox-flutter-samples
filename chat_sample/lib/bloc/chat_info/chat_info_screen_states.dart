import 'package:quickblox_sdk/models/qb_dialog.dart';
import 'package:quickblox_sdk/models/qb_user.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class ChatInfoScreenStates {}

class ChatConnectingState extends ChatInfoScreenStates {}

class ChatConnectedState extends ChatInfoScreenStates {
  final int userId;

  ChatConnectedState(this.userId);
}

class ChatConnectingErrorState extends ChatInfoScreenStates {
  final String error;

  ChatConnectingErrorState(this.error);
}

class UpdateChatInProgressState extends ChatInfoScreenStates {}

class UpdateChatSuccessState extends ChatInfoScreenStates {
  final QBDialog dialog;

  UpdateChatSuccessState(this.dialog);
}

class UpdateChatErrorState extends ChatInfoScreenStates {
  final String error;

  UpdateChatErrorState(this.error);
}

class LoadUsersSuccessState extends ChatInfoScreenStates {
  final List<QBUser?> users;

  LoadUsersSuccessState(this.users);
}

class IncomingSystemMessageState extends ChatInfoScreenStates {}

class SavedUserErrorState extends ChatInfoScreenStates {}
