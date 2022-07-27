import 'package:chat_sample/models/user_wrapper.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class SelectUsersScreenEvents {}

class LoadUsersEvent extends SelectUsersScreenEvents {}

class LoadNextUsersEvent extends SelectUsersScreenEvents {}

class ChangedSelectedUsersEvent extends SelectUsersScreenEvents {
  final QBUserWrapper user;
  final bool remove;

  ChangedSelectedUsersEvent(this.user, this.remove);
}

class SearchUsersEvent extends SelectUsersScreenEvents {
  final String text;

  SearchUsersEvent(this.text);
}

class SearchNextUsersEvent extends SelectUsersScreenEvents {}

class LeaveSelectUsersScreenEvent extends SelectUsersScreenEvents {}

class CreatePrivateChatEvent extends SelectUsersScreenEvents {
  final List<int> selectedUsersIds;

  CreatePrivateChatEvent(this.selectedUsersIds);
}
