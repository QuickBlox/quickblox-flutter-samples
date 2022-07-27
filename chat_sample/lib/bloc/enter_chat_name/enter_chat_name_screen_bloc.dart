import 'dart:async';

import 'package:chat_sample/data/chat_repository.dart';
import 'package:chat_sample/data/device_repository.dart';
import 'package:chat_sample/data/storage_repository.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/chat/constants.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';

import '../base_bloc.dart';
import 'enter_chat_name_screen_events.dart';
import 'enter_chat_name_screen_states.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class EnterChatNameScreenBloc
    extends Bloc<EnterChatNameScreenEvents, EnterChatNameScreenStates, String>
    with ConnectionListener {
  static const int CHAT_NAME_MIN_LENGTH = 3;
  static const int CHAT_NAME_MAX_LENGTH = 20;

  final ChatRepository _chatRepository = ChatRepository();
  final DeviceRepository _deviceRepository = DeviceRepository();
  final StorageRepository _storageRepository = StorageRepository();

  String? _chatName;
  int? _userId;

  @override
  void init() {
    super.init();
    _deviceRepository.addConnectionListener(this);
    _restoreSavedUserId();
  }

  @override
  Future<void> onReceiveEvent(EnterChatNameScreenEvents receivedEvent) async {
    if (receivedEvent is ChangedChatNameEvent) {
      _chatName = receivedEvent.chatName;
      _validateChatName(receivedEvent.chatName);
    }
    if (receivedEvent is CreateGroupChatEvent) {
      if (receivedEvent.selectedUsersIds.isNotEmpty) {
        states?.add(CreatingDialogState());
        _createGroupChat(receivedEvent.selectedUsersIds);
      }
    }
  }

  void _restoreSavedUserId() async {
    int userId = await _storageRepository.getUserId();
    if (userId != StorageRepository.NOT_SAVED_USER_ID) {
      _userId = userId;
    } else {
      states?.add(ErrorState("Saved user does not exist"));
    }
  }

  void _validateChatName(String chatName) {
    if (chatName.length >= CHAT_NAME_MIN_LENGTH && chatName.length <= CHAT_NAME_MAX_LENGTH) {
      states?.add(ChangedChatNameState(true));
    } else {
      states?.add(ChangedChatNameState(false));
    }
  }

  void _createGroupChat(List<int> selectedUsersIds) async {
    if (_userId == null) {
      states?.add(ErrorState("UserId is null"));
      return;
    }
    if (selectedUsersIds.length > 1) {
      selectedUsersIds.add(_userId!);
      try {
        QBDialog? dialog = await _chatRepository.createDialog(
            selectedUsersIds, _chatName!, QBChatDialogTypes.GROUP_CHAT);
        if (dialog != null && dialog.id != null) {
          states?.add(CreationFinishedState(dialog.id!));
        } else {
          states?.add(ErrorState("Dialog has not been created"));
        }
      } on PlatformException catch (e) {
        states?.add(ErrorState(makeErrorMessage(e)));
      }
    }
  }
}
