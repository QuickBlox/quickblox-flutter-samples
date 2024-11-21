import 'dart:async';

import 'package:chat_sample/data/auth_repository.dart';
import 'package:chat_sample/data/chat_repository.dart';
import 'package:chat_sample/data/device_repository.dart';
import 'package:chat_sample/data/repository_exception.dart';
import 'package:chat_sample/data/storage_repository.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/chat/constants.dart';
import 'package:quickblox_sdk/mappers/qb_message_mapper.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';
import 'package:quickblox_sdk/models/qb_message.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';

import '../../main.dart';
import '../base_bloc.dart';
import 'dialogs_screen_events.dart';
import 'dialogs_screen_states.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class DialogsScreenBloc extends Bloc<DialogsScreenEvents, DialogsScreenStates, void>
    with ConnectionListener {
  final ChatRepository _chatRepository = ChatRepository();
  final StorageRepository _storageRepository = StorageRepository();
  final DeviceRepository _deviceRepository = DeviceRepository();
  final AuthRepository _authRepository = AuthRepository();

  StreamSubscription? _incomingMessagesSubscription;
  StreamSubscription? _incomingSystemMessagesSubscription;
  StreamSubscription? _connectedChatSubscription;
  List<QBDialog?> _dialogsList = <QBDialog>[];

  int? _currentUserId;
  bool _isNeedUpdateBlocData = true;
  List<QBDialog> _dialogsToDeleteList = [];

  @override
  void init() async {
    super.init();
    _initBlocData();
  }

  void _initBlocData() async {
    await _subscribeConnectedChat();
    _deviceRepository.addConnectionListener(this);
    _dialogsToDeleteList.clear();
    states?.add(ChatConnectingState());

    await _restoreSavedUserId();
    await _connectChat();
    await _subscribeIncomingMessages();
    await _subscribeIncomingSystemMessages();
  }

  @override
  void dispose() async {
    await _unsubscribeListeners();
    _deviceRepository.removeConnectionListener(this);
    super.dispose();
  }

  @override
  void onBackgroundMode() async {
    await _unsubscribeListeners();
    await _chatRepository.disconnect();
    _deviceRepository.removeConnectionListener(this);
  }

  @override
  void onForegroundMode() {
    _initBlocData();
  }

  @override
  Future<void> onReceiveEvent(DialogsScreenEvents receivedEvent) async {
    if (receivedEvent is UpdateChatsEvent) {
      await _updateDialogs();
    }
    if (receivedEvent is LogoutEvent) {
      _logout();
    }
    if (receivedEvent is ChangedChatsToDeleteEvent) {
      _handleChangeDialogsToDelete(receivedEvent.delete, receivedEvent.dialog);
    }
    if (receivedEvent is DeleteChatsEvent) {
      states?.add(DeleteInProgressState());
      await _deleteDialogs();
      await Future.delayed(const Duration(seconds: 1), () {
        states?.add(ModeListChatsState());
      });
    }
    if (receivedEvent is ModeDeleteChatsEvent) {
      _dialogsToDeleteList.clear();
      states?.add(ModeDeleteChatsState());
      await Future.delayed(const Duration(milliseconds: 300), () {
        states?.add(UpdateChatsSuccessState(_dialogsList));
      });
    }
    if (receivedEvent is ModeListChatsEvent) {
      _dialogsToDeleteList.clear();
      states?.add(ModeListChatsState());
    }
    if (receivedEvent is LeaveDialogsScreenEvent) {
      await _unsubscribeListeners();
      _isNeedUpdateBlocData = false;
    }
    if (receivedEvent is ReturnDialogsScreenEvent) {
      _isNeedUpdateBlocData = true;
      _deviceRepository.addConnectionListener(this);
      await _subscribeIncomingMessages();
      await _subscribeIncomingSystemMessages();
    }
  }

  Future<void> _subscribeConnectedChat() async {
    if (_connectedChatSubscription != null) {
      return;
    }
    try {
      _connectedChatSubscription =
          await QB.chat.subscribeChatEvent(QBChatEvents.CONNECTED, _processConnectedChatEvent);
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    }
  }

  void _processConnectedChatEvent(dynamic data) async {
    await _updateDialogs();
  }

  Future<void> _unsubscribeConnectedChat() async {
    await _connectedChatSubscription?.cancel();
    _connectedChatSubscription = null;
  }

  Future<void> _unsubscribeListeners() async {
    await _unsubscribeConnectedChat();
    await _unsubscribeIncomingMessages();
    await _unsubscribeIncomingSystemMessages();
  }

  Future<void> _restoreSavedUserId() async {
    int userId = await _storageRepository.getUserId();
    if (userId != StorageRepository.NOT_SAVED_USER_ID) {
      _currentUserId = userId;
    } else {
      states?.add(SavedUserErrorState());
    }
  }

  Future<void> _connectChat() async {
    if (!_isNeedUpdateBlocData) {
      return;
    }

    try {
      bool isNotExistInternetConnection = !await checkInternetConnection();
      if (isNotExistInternetConnection) {
        states?.add(ConnectionTypeChanged(false, false));
        return;
      }

      bool connected = await _chatRepository.isConnected() ?? false;
      if (connected) {
        await _updateDialogs();
      } else {
        await _chatRepository.connect(_currentUserId, DEFAULT_USER_PASSWORD);
      }
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    } on RepositoryException catch (e) {
      states?.add(ErrorState(e.message));
    }
  }

  void _handleChangeDialogsToDelete(bool delete, QBDialog dialog) {
    if (delete) {
      _dialogsToDeleteList.remove(dialog);
    } else {
      _dialogsToDeleteList.add(dialog);
    }
    states?.add(ChangedChatsToDeleteState(_dialogsToDeleteList.length));
  }

  Future<void> _updateDialogs() async {
    states?.add(UpdateChatsInProgressState());
    _dialogsList = await _chatRepository.loadDialogs();
    states?.add(UpdateChatsSuccessState(_dialogsList));

    for (final element in _dialogsList) {
      try {
        if (element?.type != QBChatDialogTypes.CHAT) {
          bool isJoined = await _chatRepository.isJoinedDialog(element?.id);
          if (!isJoined) {
            await _joinDialog(element?.id);
          }
        }
      } on PlatformException catch (e) {
        states?.add(UpdateChatsErrorState(makeErrorMessage(e)));
      } on RepositoryException catch (e) {
        states?.add(UpdateChatsErrorState(e.message));
      }
    }
  }

  Future<void> _joinDialog(String? dialogId) async {
    try {
      await _chatRepository.joinDialog(dialogId);
    } on PlatformException catch (e) {
      if (!e.code.contains("You are already joined to the dialog.") &&
          !e.code.contains("Cannot create/join room when already creating/joining/joined.")) {
        states?.add(ErrorState(makeErrorMessage(e)));
      }
    } on RepositoryException catch (e) {
      states?.add(ErrorState(e.message));
    }
  }

  void _logout() async {
    ConnectionType connectionType = await _deviceRepository.checkInternetConnection();
    if (connectionType == ConnectionType.none) {
      states?.add(LogoutErrorState("Unable to perform operation without connection"));
      return;
    }
    try {
      states?.add(LogoutInProgressState());
      await _authRepository.logout();
      await _chatRepository.disconnect();
      _storageRepository.cleanCredentials();
      states?.add(LogoutSuccessState());
    } on PlatformException catch (e) {
      states?.add(LogoutErrorState(makeErrorMessage(e)));
    }
  }

  Future<void> _subscribeIncomingMessages() async {
    await _unsubscribeIncomingMessages();

    try {
      _incomingMessagesSubscription = await QB.chat
          .subscribeChatEvent(QBChatEvents.RECEIVED_NEW_MESSAGE, _processIncomingMessageEvent);
    } on PlatformException catch (exception) {
      states?.add(ErrorState(makeErrorMessage(exception)));
    }
  }

  void _processIncomingMessageEvent(dynamic data) async {
    Map<String, Object> payload = Map<String, Object>.from(data["payload"]);
    QBMessage? message = QBMessageMapper.mapToQBMessage(payload);
    QBDialog? dialog;
    if (message != null && message.dialogId != null && _hasDialog(message.dialogId!)) {
      Map<String?, Object?> properties =
          Map<String?, Object?>.from(payload["properties"] as Map<Object?, Object?>);
      String? notificationType = properties["notification_type"] as String?;
      if (notificationType == ChatRepository.NOTIFICATION_TYPE_LEFT.toString() &&
          message.senderId == _currentUserId) {
        return;
      }
      dialog = _dialogsList.firstWhere(
          (element) => element != null && element.id != null && element.id == message.dialogId);
      dialog?.lastMessage = message.body;
      dialog?.lastMessageDateSent = message.dateSent;
      dialog?.unreadMessagesCount = dialog.unreadMessagesCount ?? 0;
      dialog?.unreadMessagesCount = dialog.unreadMessagesCount! + 1;
      _dialogsList.remove(dialog);
    } else {
      try {
        dialog = await _chatRepository.getDialog(message?.dialogId);
      } on RepositoryException catch (e) {
        states?.add(ErrorState(e.message));
      }
    }
    if (dialog != null) {
      _dialogsList.insert(0, dialog);
    }

    states?.add(UpdateChatsSuccessState(_dialogsList));
  }

  Future<void> _unsubscribeIncomingMessages() async {
    await _incomingMessagesSubscription?.cancel();
    _incomingMessagesSubscription = null;
  }

  Future<void> _subscribeIncomingSystemMessages() async {
    if (_incomingSystemMessagesSubscription == null) {
      try {
        _incomingSystemMessagesSubscription = await QB.chat.subscribeChatEvent(
            QBChatEvents.RECEIVED_SYSTEM_MESSAGE, _processIncomingSystemMessageEvent);
      } on PlatformException catch (e) {
        states?.add(ErrorState(makeErrorMessage(e)));
      } on RepositoryException catch (e) {
        states?.add(ErrorState(e.message));
      }
    }
  }

  Future<void> _processIncomingSystemMessageEvent(dynamic data) async {
    Map<String, Object> map = Map<String, Object>.from(data);
    Map<String?, Object?> payload =
        Map<String?, Object?>.from(map["payload"] as Map<Object?, Object?>);
    Map<String?, Object?> properties =
        Map<String?, Object?>.from(payload["properties"] as Map<Object?, Object?>);

    String? dialogId = payload["dialogId"] as String?;
    int? senderId = payload["senderId"] as int?;
    String? propertyDialogId = properties["dialogId"] as String?;

    if (senderId == _currentUserId) {
      return;
    }

    if (dialogId == "null") {
      // now iOS returns - String "null" in payload["dialogId"]
      dialogId = null;
    }
    if (dialogId == null) {
      dialogId = propertyDialogId;
    }

    var dialog;
    if (_hasDialog(dialogId!)) {
      dialog = _dialogsList
          .firstWhere((element) => element != null && element.id != null && element.id == dialogId);
    } else {
      dialog = await _chatRepository.getDialog(dialogId);
      if (dialog?.type != QBChatDialogTypes.CHAT) {
        bool isJoined = await _chatRepository.isJoinedDialog(dialog?.id);
        if (!isJoined) {
          await _joinDialog(dialog?.id);
        }
      }
    }
    _dialogsList.remove(dialog);
    _dialogsList.insert(0, dialog);
    states?.add(UpdateChatsSuccessState(_dialogsList));
  }

  Future<void> _unsubscribeIncomingSystemMessages() async {
    await _incomingSystemMessagesSubscription?.cancel();
    _incomingSystemMessagesSubscription = null;
  }

  bool _hasDialog(String dialogId) {
    bool has = false;
    var dialog = _dialogsList.firstWhere(
        (element) => element != null && element.id != null && element.id == dialogId,
        orElse: () => null);
    if (dialog != null) {
      has = true;
    }
    return has;
  }

  Future<void> _deleteDialogs() async {
    for (QBDialog dialog in _dialogsToDeleteList) {
      if (dialog.id == null) {
        return;
      }
      try {
        switch (dialog.type) {
          case QBChatDialogTypes.GROUP_CHAT:
            await _sendNotificationMessageLeftChat(dialog.id);
            await _sendSystemMessagesLeftChat(dialog);
            await _leaveChat(dialog.id);
            break;
          case QBChatDialogTypes.CHAT:
            await _chatRepository.deleteDialog(dialog.id);
            break;
          case QBChatDialogTypes.PUBLIC_CHAT:
            states?.add(DeleteErrorState("You can’t leave from ${dialog.name}"));
            break;
        }
      } on PlatformException catch (e) {
        states?.add(DeleteErrorState(makeErrorMessage(e)));
      } on RepositoryException catch (e) {
        states?.add(DeleteErrorState(e.message));
      }
    }
  }

  Future<void> _sendNotificationMessageLeftChat(String? dialogId) async {
    String messageBody = await _storageRepository.getUserFullName() + " has left";

    await _chatRepository.sendNotificationMessage(
        dialogId, messageBody, ChatRepository.NOTIFICATION_TYPE_LEFT);
  }

  Future<void> _sendSystemMessagesLeftChat(QBDialog dialog) async {
    for (int occupantId in dialog.occupantsIds ?? []) {
      if (occupantId != _currentUserId) {
        await _chatRepository.sendSystemMessage(
            dialog.id, occupantId, ChatRepository.NOTIFICATION_TYPE_LEFT);
      }
    }
  }

  Future<void> _leaveChat(String? dialogId) async {
    if (_currentUserId == null) {
      states?.add(DeleteErrorState("UserId is null"));
      return;
    }
    await _chatRepository.leaveDialog(dialogId);
    await _chatRepository.updateDialog(dialogId, removeUsers: [_currentUserId!]);
  }

  @override
  void connectionTypeChanged(ConnectionType type) async {
    switch (type) {
      case ConnectionType.wifi:
        states?.add(ConnectionTypeChanged(true, true));
        if (_isNeedUpdateBlocData) {
          _initBlocData();
        }
        break;
      case ConnectionType.mobile:
        states?.add(ConnectionTypeChanged(true, false));
        if (_isNeedUpdateBlocData) {
          _initBlocData();
        }
        break;
      case ConnectionType.none:
        await _unsubscribeListeners();
        states?.add(ConnectionTypeChanged(false, false));
        break;
    }
  }
}
