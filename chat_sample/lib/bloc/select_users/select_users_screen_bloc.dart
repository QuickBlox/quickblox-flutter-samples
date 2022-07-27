import 'dart:collection';

import 'package:chat_sample/bloc/select_users/select_users_screen_events.dart';
import 'package:chat_sample/bloc/select_users/select_users_screen_states.dart';
import 'package:chat_sample/data/chat_repository.dart';
import 'package:chat_sample/data/device_repository.dart';
import 'package:chat_sample/data/repository_exception.dart';
import 'package:chat_sample/data/storage_repository.dart';
import 'package:chat_sample/data/users_repository.dart';
import 'package:chat_sample/models/user_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/chat/constants.dart';
import 'package:quickblox_sdk/models/qb_dialog.dart';
import 'package:quickblox_sdk/models/qb_filter.dart';
import 'package:quickblox_sdk/models/qb_sort.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/users/constants.dart';

import '../../main.dart';
import '../base_bloc.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class SelectUsersScreenBloc extends Bloc<SelectUsersScreenEvents, SelectUsersScreenStates, String>
    with ConnectionListener {
  static const int PAGE_SIZE = 100;

  final StorageRepository _storageRepository = StorageRepository();
  final DeviceRepository _deviceRepository = DeviceRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final ChatRepository _chatRepository = ChatRepository();

  final Set<QBUserWrapper> _loadedUsersSet = LinkedHashSet();
  final Set<QBUserWrapper> _selectedUsersSet = HashSet();

  String _searchText = "";
  String? _dialogId;
  QBDialog? _dialog;
  int? _userId;
  int _currentPage = 0;
  int _currentSearchPage = 0;

  @override
  void init() {
    super.init();
    _deviceRepository.addConnectionListener(this);
    _initBlocData();
  }

  void _initBlocData() async {
    _restoreSavedUserId();
    await _connectChat();
    _dialog = null;
    _selectedUsersSet.clear();
    _loadedUsersSet.clear();
    _currentSearchPage = 1;
    _currentPage = 1;
    _loadUsers();
  }

  @override
  void setArgs(String arguments) {
    _dialogId = arguments;
    _updateDialog();
  }

  @override
  void onBackgroundMode() async {
    await _chatRepository.disconnect();
    _deviceRepository.removeConnectionListener(this);
  }

  @override
  void onForegroundMode() {
    _initBlocData();
  }

  @override
  void onReceiveEvent(SelectUsersScreenEvents receivedEvent) {
    if (receivedEvent is ChangedSelectedUsersEvent) {
      _handleChangedSelectedUsers(receivedEvent.remove, receivedEvent.user);
    }
    if (receivedEvent is LoadUsersEvent) {
      _currentPage = 1;
      _updateDialog();
      _loadUsers();
    }
    if (receivedEvent is LoadNextUsersEvent) {
      _loadUsers();
    }
    if (receivedEvent is SearchUsersEvent) {
      _currentSearchPage = 1;
      _searchText = receivedEvent.text;
      _searchUsers();
    }
    if (receivedEvent is SearchNextUsersEvent) {
      _searchUsers();
    }
    if (receivedEvent is LeaveSelectUsersScreenEvent) {
      _deviceRepository.removeConnectionListener(this);
    }
    if (receivedEvent is CreatePrivateChatEvent) {
      if (receivedEvent.selectedUsersIds.isNotEmpty) {
        states?.add(CreatingDialogState());
        _createPrivateChat(receivedEvent.selectedUsersIds);
      }
    }
  }

  Future<void> _updateDialog() async {
    if (_dialogId != null) {
      try {
        _dialog = await _chatRepository.getDialog(_dialogId);
      } on RepositoryException catch (e) {
        states?.add(ErrorState("Unable to get Dialog"));
      }
    }
  }

  void _handleChangedSelectedUsers(bool remove, QBUserWrapper userWrapper) {
    if (remove) {
      _unselectUser(userWrapper);
    } else {
      _selectUser(userWrapper);
    }
    _prepareSelectedUsersIds();
  }

  void _prepareSelectedUsersIds() {
    List<int> selectedUsersIds = [];
    _selectedUsersSet.forEach((element) {
      if (element.id != null) {
        selectedUsersIds.add(element.id!);
      }
    });
    states?.add(ChangedSelectedUsersState(selectedUsersIds));
  }

  void _unselectUser(QBUserWrapper userWrapper) {
    if (_selectedUsersSet.contains(userWrapper)) {
      _selectedUsersSet.remove(userWrapper);
    }
    if (_loadedUsersSet.contains(userWrapper) && userWrapper.id != null) {
      QBUserWrapper? loadedUser = _getLoadedUser(userWrapper.id!);
      loadedUser?.checked = false;
    }
  }

  void _selectUser(QBUserWrapper userWrapper) {
    if (!_selectedUsersSet.contains(userWrapper)) {
      _selectedUsersSet.add(userWrapper);
    }
    if (_loadedUsersSet.contains(userWrapper) && userWrapper.id != null) {
      QBUserWrapper? loadedUser = _getLoadedUser(userWrapper.id!);
      loadedUser?.checked = true;
    }
  }

  QBUserWrapper? _getLoadedUser(int id) {
    for (QBUserWrapper userWrapper in _loadedUsersSet) {
      if (userWrapper.id == id) {
        return userWrapper;
      }
    }
    return null;
  }

  void _wrapQBUsers(List<QBUser?> users) {
    users.forEach((element) {
      if (element?.id != _userId) {
        _loadedUsersSet.add(QBUserWrapper(false, element));
      }
    });

    _selectedUsersSet.forEach((element) {
      if (_loadedUsersSet.contains(element) && element.id != null) {
        _getLoadedUser(element.id!)?.checked = true;
      }
    });
  }

  void _restoreSavedUserId() async {
    int userId = await _storageRepository.getUserId();
    if (userId != StorageRepository.NOT_SAVED_USER_ID) {
      _userId = userId;
    } else {
      states?.add(ErrorState("Current user does not exist"));
    }
  }

  void _loadUsers() async {
    if (_currentPage == 1) {
      _loadedUsersSet.clear();
      states?.add(LoadUsersInProgressState());
    } else {
      states?.add(LoadNextUsersInProgressState());
    }

    try {
      QBSort sort = QBSort();
      sort.field = QBUsersSortFields.UPDATED_AT;
      sort.type = QBUsersSortTypes.STRING;
      sort.ascending = false;

      List<QBUser?> users = await _usersRepository.getUsers(_currentPage, PAGE_SIZE, sort: sort);

      _dialog?.occupantsIds?.forEach((occupantId) {
        users.removeWhere((user) => user?.id == occupantId);
      });
      _wrapQBUsers(users);

      states?.add(LoadUsersSuccessState(_loadedUsersSet.toList()));
      _currentPage++;
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    }
  }

  void _createPrivateChat(List<int> selectedUsersIds) async {
    if (_userId == null) {
      states?.add(ErrorState("UserId is null"));
      return;
    }
    if (selectedUsersIds.length == 1) {
      selectedUsersIds.add(_userId!);
      try {
        // we have to pass dialog name and add current user ID. Dialog name should not be required for private chat
        QBDialog? dialog =
            await _chatRepository.createDialog(selectedUsersIds, "private", QBChatDialogTypes.CHAT);
        if (dialog != null && dialog.id != null) {
          states?.add(CreatedDialogState(dialog.id!));
        }
      } on PlatformException catch (e) {
        states?.add(CreateDialogErrorState(makeErrorMessage(e)));
        _prepareSelectedUsersIds();
      }
    }
  }

  void _searchUsers() async {
    if (_currentSearchPage == 1) {
      _loadedUsersSet.clear();
      states?.add(LoadUsersInProgressState());
    } else {
      states?.add(LoadNextUsersInProgressState());
    }

    try {
      QBFilter filter = QBFilter();
      filter.field = QBUsersFilterFields.FULL_NAME;
      filter.operator = QBUsersFilterOperators.IN;
      filter.type = QBUsersFilterTypes.STRING;
      filter.value = _searchText;

      List<QBUser?> users =
          await _usersRepository.getUsers(_currentSearchPage, PAGE_SIZE, filter: filter);
      _wrapQBUsers(users);

      states?.add(LoadUsersSuccessState(_loadedUsersSet.toList()));
      _currentSearchPage++;
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    }
  }

  Future<void> _connectChat() async {
    try {
      bool connected = await _chatRepository.isConnected() ?? false;
      if (!connected) {
        await _chatRepository.connect(_userId, DEFAULT_USER_PASSWORD);
      }
    } on PlatformException catch (e) {
      states?.add(ErrorState(makeErrorMessage(e)));
    } on RepositoryException catch (e) {
      states?.add(ErrorState(e.message));
    }
  }

  @override
  void connectionTypeChanged(ConnectionType type) {
    if (type == ConnectionType.wifi || type == ConnectionType.mobile) {
      _initBlocData();
    }
  }
}
