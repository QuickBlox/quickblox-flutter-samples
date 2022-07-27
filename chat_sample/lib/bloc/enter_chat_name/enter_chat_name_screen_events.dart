/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class EnterChatNameScreenEvents {}

class ChangedChatNameEvent extends EnterChatNameScreenEvents {
  final String chatName;

  ChangedChatNameEvent(this.chatName);
}

class CreateGroupChatEvent extends EnterChatNameScreenEvents {
  final List<int> selectedUsersIds;

  CreateGroupChatEvent(this.selectedUsersIds);
}
