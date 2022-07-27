import 'package:chat_sample/models/message_wrapper.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class ChatScreenStates {}

class ChatConnectingState extends ChatScreenStates {}

class ChatConnectedState extends ChatScreenStates {
  final int userId;

  ChatConnectedState(this.userId);
}

class ChatConnectingErrorState extends ChatScreenStates {
  final String error;

  ChatConnectingErrorState(this.error);
}

class UpdateChatInProgressState extends ChatScreenStates {}

class UpdateChatSuccessState extends ChatScreenStates {
  final QBDialog dialog;

  UpdateChatSuccessState(this.dialog);
}

class UpdateChatErrorState extends ChatScreenStates {
  final String error;

  UpdateChatErrorState(this.error);
}

class LoadMessagesInProgressState extends ChatScreenStates {}

class LoadMessagesSuccessState extends ChatScreenStates {
  final List<QBMessageWrapper> messages;
  final bool hasMore;

  LoadMessagesSuccessState(this.messages, this.hasMore);
}

class LoadNextMessagesErrorState extends ChatScreenStates {
  final String error;

  LoadNextMessagesErrorState(this.error);
}

class SendMessageErrorState extends ChatScreenStates {
  final String error;
  final String? messageToSend;

  SendMessageErrorState(this.error, this.messageToSend);
}

class OpponentIsTypingState extends ChatScreenStates {
  final List<String> typingNames;

  OpponentIsTypingState(this.typingNames);
}

class OpponentStoppedTypingState extends ChatScreenStates {}

class LeaveChatErrorState extends ChatScreenStates {
  final String error;

  LeaveChatErrorState(this.error);
}

class DeleteChatErrorState extends ChatScreenStates {
  final String error;

  DeleteChatErrorState(this.error);
}

class ReturnToDialogsState extends ChatScreenStates {}

class SavedUserErrorState extends ChatScreenStates {}

class ErrorState extends ChatScreenStates {
  final String error;

  ErrorState(this.error);
}
