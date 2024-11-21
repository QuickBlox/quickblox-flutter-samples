import 'dart:async';

import 'package:chat_sample/data/chat_repository.dart';
import 'package:chat_sample/data/device_repository.dart';
import 'package:chat_sample/data/repository_exception.dart';
import 'package:chat_sample/data/storage_repository.dart';
import 'package:chat_sample/data/users_repository.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/chat/constants.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

import '../../main.dart';
import '../base_bloc.dart';
import 'chat_info_screen_events.dart';
import 'chat_info_screen_states.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class ChatInfoScreenBloc extends Bloc<ChatInfoScreenEvents, ChatInfoScreenStates, String>
    with ConnectionListener {
  final ChatRepository _chatRepository = ChatRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final DeviceRepository _deviceRepository = DeviceRepository();
  final StorageRepository _storageRepository = StorageRepository();

  int? _userId;
  String? _dialogId;
  QBDialog? _dialog;

  StreamSubscription? _incomingSystemMessagesSubscription;

  @override
  void init() {
    super.init();
    _deviceRepository.addConnectionListener(this);
    states?.add(ChatConnectingState());
    _initBlocData();
  }

  void _initBlocData() async {
    _restoreSavedUserId();
    await _connectChat();
  }

  @override
  void setArgs(String arguments) {
    _dialogId = arguments;
  }

  @override
  void onBackgroundMode() async {
    _unsubscribeIncomingSystemMessages();
    await _chatRepository.disconnect();
    _deviceRepository.removeConnectionListener(this);
  }

  @override
  void onForegroundMode() {
    _initBlocData();
  }

  @override
  void dispose() {
    _unsubscribeIncomingSystemMessages();
    _deviceRepository.removeConnectionListener(this);
    super.dispose();
  }

  @override
  void onReceiveEvent(ChatInfoScreenEvents receivedEvent) async {
    if (receivedEvent is UpdateChatEvent) {
      try {
        await _updateInfo();
        if (_dialog?.type != QBChatDialogTypes.CHAT) {
          bool isJoined = await _chatRepository.isJoinedDialog(_dialogId);
          if (!isJoined) {
            await _chatRepository.joinDialog(_dialogId);
          }
        }
      } on PlatformException catch (e) {
        states?.add(UpdateChatErrorState(makeErrorMessage(e)));
      } on RepositoryException catch (e) {
        states?.add(UpdateChatErrorState(e.message));
      }
      _subscribeIncomingSystemMessages();
    }
  }

  void _restoreSavedUserId() async {
    int userId = await _storageRepository.getUserId();
    if (userId != StorageRepository.NOT_SAVED_USER_ID) {
      _userId = userId;
    } else {
      states?.add(SavedUserErrorState());
    }
  }

  Future<void> _connectChat() async {
    try {
      bool isNotExistInternetConnection = !await checkInternetConnection();
      if (isNotExistInternetConnection) {
        return;
      }

      bool connected = await _chatRepository.isConnected() ?? false;
      if (!connected) {
        await _chatRepository.connect(_userId, DEFAULT_USER_PASSWORD);
      }
      states?.add(ChatConnectedState(_userId!));
    } on PlatformException catch (e) {
      states?.add(ChatConnectingErrorState(makeErrorMessage(e)));
    } on RepositoryException catch (e) {
      states?.add(ChatConnectingErrorState(e.message));
    }
  }

  Future<void> _updateInfo() async {
    try {
      states?.add(UpdateChatInProgressState());
      _dialog = await _chatRepository.getDialog(_dialogId);
      if (_dialog != null) {
        states?.add(UpdateChatSuccessState(_dialog!));
        List<QBUser?> users = await _usersRepository.getUsersByIds(_dialog?.occupantsIds);
        users.removeWhere((element) => element == null);
        states?.add(LoadUsersSuccessState(users));
      } else {
        states?.add(UpdateChatErrorState("Dialog does not exist"));
      }
    } on PlatformException catch (e) {
      states?.add(UpdateChatErrorState(makeErrorMessage(e)));
    } on RepositoryException catch (e) {
      states?.add(UpdateChatErrorState(e.message));
    }
  }

  void _subscribeIncomingSystemMessages() async {
    if (_incomingSystemMessagesSubscription == null) {
      try {
        _incomingSystemMessagesSubscription = await QB.chat.subscribeChatEvent(
            QBChatEvents.RECEIVED_SYSTEM_MESSAGE, _processIncomingSystemMessageEvent);
      } on PlatformException catch (e) {
        states?.add(UpdateChatErrorState(makeErrorMessage(e)));
      }
    }
  }

  void _processIncomingSystemMessageEvent(dynamic data) {
    const String NOTIFICATION_TYPE_ADD_USER = "2";
    const String NOTIFICATION_TYPE_LEFT_USER = "3";

    Map<String, Object> map = Map<String, Object>.from(data);
    Map<String?, Object?> payload =
        Map<String?, Object?>.from(map["payload"] as Map<Object?, Object?>);
    Map<String?, Object?> properties =
        Map<String?, Object?>.from(payload["properties"] as Map<Object?, Object?>);
    String? dialogId = properties["dialog_id"] as String?;
    String? notificationType = properties["notification_type"] as String?;
    if (dialogId != null && dialogId == _dialogId && notificationType != null
        && (notificationType == NOTIFICATION_TYPE_ADD_USER || notificationType == NOTIFICATION_TYPE_LEFT_USER)) {
      states?.add(IncomingSystemMessageState());
    }
  }

  void _unsubscribeIncomingSystemMessages() {
    _incomingSystemMessagesSubscription?.cancel();
    _incomingSystemMessagesSubscription = null;
  }

  @override
  void connectionTypeChanged(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
      case ConnectionType.mobile:
        _initBlocData();
        break;
      case ConnectionType.none:
        break;
    }
  }
}
