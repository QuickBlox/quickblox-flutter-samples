import 'package:quickblox_sdk/models/qb_dialog.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class DialogsScreenEvents {}

class UpdateChatsEvent extends DialogsScreenEvents {}

class LogoutEvent extends DialogsScreenEvents {}

class ChangedChatsToDeleteEvent extends DialogsScreenEvents {
  final QBDialog dialog;
  final bool delete;

  ChangedChatsToDeleteEvent(this.dialog, this.delete);
}

class PressedChatEvent extends DialogsScreenEvents {
  final QBDialog dialog;

  PressedChatEvent(this.dialog);
}

class DeleteChatsEvent extends DialogsScreenEvents {}

class ModeListChatsEvent extends DialogsScreenEvents {}

class ModeDeleteChatsEvent extends DialogsScreenEvents {}

class LeaveDialogsScreenEvent extends DialogsScreenEvents {}

class ReturnDialogsScreenEvent extends DialogsScreenEvents {}
