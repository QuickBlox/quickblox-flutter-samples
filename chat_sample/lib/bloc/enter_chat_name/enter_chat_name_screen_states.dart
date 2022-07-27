/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class EnterChatNameScreenStates {}

class ChangedChatNameInProgressState extends EnterChatNameScreenStates {}

class ChangedChatNameState extends EnterChatNameScreenStates {
  final bool allowFinish;

  ChangedChatNameState(this.allowFinish);
}

class CreationFinishedState extends EnterChatNameScreenStates {
  final String dialogId;

  CreationFinishedState(this.dialogId);
}

class CreatingDialogState extends EnterChatNameScreenStates {}

class ErrorState extends EnterChatNameScreenStates {
  final String error;

  ErrorState(this.error);
}
