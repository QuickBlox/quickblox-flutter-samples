import 'package:quickblox_sdk/models/qb_dialog.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class DialogsScreenStates {}

class ConnectionTypeChanged extends DialogsScreenStates {
  final bool isConnected;
  final bool isWiFi;

  ConnectionTypeChanged(this.isConnected, this.isWiFi);
}

class UpdateChatsInProgressState extends DialogsScreenStates {}

class UpdateChatsSuccessState extends DialogsScreenStates {
  final List<QBDialog?> dialogs;

  UpdateChatsSuccessState(this.dialogs);
}

class UpdateChatsErrorState extends DialogsScreenStates {
  final String error;

  UpdateChatsErrorState(this.error);
}

class ChatConnectingState extends DialogsScreenStates {}

class SavedUserErrorState extends DialogsScreenStates {}

class LogoutSuccessState extends DialogsScreenStates {}

class LogoutErrorState extends DialogsScreenStates {
  final String error;

  LogoutErrorState(this.error);
}

class LogoutInProgressState extends DialogsScreenStates {}

class ChangedChatsToDeleteState extends DialogsScreenStates {
  final int dialogsCount;

  ChangedChatsToDeleteState(this.dialogsCount);
}

class DeleteInProgressState extends DialogsScreenStates {}

class DeleteErrorState extends DialogsScreenStates {
  final String error;

  DeleteErrorState(this.error);
}

class ModeListChatsState extends DialogsScreenStates {}

class ModeDeleteChatsState extends DialogsScreenStates {}

class ErrorState extends DialogsScreenStates {
  final String error;

  ErrorState(this.error);
}