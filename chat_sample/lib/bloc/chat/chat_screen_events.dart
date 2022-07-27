import 'package:quickblox_sdk/models/qb_message.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class ChatScreenEvents {}

class ConnectChatEvent extends ChatScreenEvents {}

class UpdateChatEvent extends ChatScreenEvents {}

class ReturnToDialogsEvent extends ChatScreenEvents {}

class StartTypingEvent extends ChatScreenEvents {}

class StopTypingEvent extends ChatScreenEvents {}

class UsersAddedEvent extends ChatScreenEvents {
  final List<int> addedUsersIds;

  UsersAddedEvent(this.addedUsersIds);
}

class SendMessageEvent extends ChatScreenEvents {
  final String? textMessage;

  SendMessageEvent(this.textMessage);
}

class MarkMessageRead extends ChatScreenEvents {
  final QBMessage message;

  MarkMessageRead(this.message);
}

class LeaveChatEvent extends ChatScreenEvents {}

class LeaveChatScreenEvent extends ChatScreenEvents {}

class ReturnChatScreenEvent extends ChatScreenEvents {}

class DeleteChatEvent extends ChatScreenEvents {}

class LoadNextMessagesPageEvent extends ChatScreenEvents {}
