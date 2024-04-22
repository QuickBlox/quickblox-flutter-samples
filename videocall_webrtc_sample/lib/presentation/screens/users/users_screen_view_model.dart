import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_filter.dart';
import 'package:quickblox_sdk/models/qb_sort.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:quickblox_sdk/users/constants.dart';
import 'package:quickblox_sdk/webrtc/constants.dart';
import 'package:videocall_webrtc_sample/dependency/dependency_impl.dart';
import 'package:videocall_webrtc_sample/managers/auth_manager.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';
import 'package:videocall_webrtc_sample/managers/chat_manager.dart';
import 'package:videocall_webrtc_sample/managers/storage_manager.dart';
import 'package:videocall_webrtc_sample/managers/users_manager.dart';
import 'package:videocall_webrtc_sample/presentation/utils/error_parser.dart';

import '../../../entities/user_entity.dart';
import '../../../managers/callback/call_subscription.dart';
import '../../../managers/callback/call_subscription_impl.dart';
import '../../../managers/permission_manager.dart';
import '../../base_view_model.dart';

class UsersScreenViewModel extends BaseViewModel {
  static const int PAGE_SIZE = 100;

  final AuthManager _authManager = DependencyImpl.getInstance().getAuthManager();
  final ChatManager _chatManager = DependencyImpl.getInstance().getChatManager();
  final StorageManager _storageManager = DependencyImpl.getInstance().getStorageManager();
  final UsersManager _usersManager = DependencyImpl.getInstance().getUsersManager();
  final CallManager _callManager = DependencyImpl.getInstance().getCallManager();
  final PermissionManager _permissionManager = DependencyImpl.getInstance().getPermissionManager();

  final LinkedHashSet<UserEntity> loadedUsersSet = LinkedHashSet<UserEntity>();
  final HashSet<UserEntity> selectedUsersSet = HashSet<UserEntity>();

  bool isLoggedIn = true;
  bool isLoggingOut = false;
  int _currentPage = 1;
  int _currentSearchPage = 1;
  bool usersLoading = false;

  bool loadNextUsers = false;
  bool searchNextUsers = false;

  bool isVideoCall = false;

  bool receivedCall = false;
  CallSubscription? _callSubscription;

  List<QBUser?> getSelectedQbUsers() {
    List<QBUser?> unwrapped = [];
    for (var element in selectedUsersSet) {
      unwrapped.add(element.user);
    }
    return unwrapped;
  }

  Future<void> init() async {
    selectedUsersSet.clear();
    loadedUsersSet.clear();

    if (Platform.isAndroid) {
      _checkNotificationPermission();
    }

    bool isConnectedToChat = await _chatManager.isConnected() ?? false;
    bool isNotConnectedToChat = !isConnectedToChat;

    if (isNotConnectedToChat) {
      await connectToChat();
    }

    await _initWebRTC();

    _callSubscription = _createCallSubscription();
    await _subscribeCall();

    await loadUsers();
  }

  Future<void> _checkNotificationPermission() async {
    bool isNotGranted = !await _permissionManager.checkNotificationPermission();
    if (isNotGranted) {
      _showError(
          "The requested permissions are required for the application to function correctly.");
    }
  }

  Future<void> connectToChat() async {
    try {
      final userId = await _storageManager.getLoggedUserId();
      final userPassword = await _storageManager.getUserPassword();
      await _chatManager.connect(userId, userPassword);
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  @override
  void dispose() {
    _unsubscribeCall();
    super.dispose();
  }

  Future<void> startAudioCall() async {
    try {
      await _callManager.startAudioCall(getSelectedQbUsers());
      receivedCall = false;
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> addVideoCallEntities(List<QBUser?> users) async {
    _callManager.addVideoCallEntities(users);
  }

  Future<List<QBUser?>> addCurrentUserToList(List<QBUser?> users) async {
    QBUser currentUser = QBUser();
    int userId = await _storageManager.getLoggedUserId();
    String userName = await _storageManager.getNameLogin();
    currentUser.fullName = userName;
    currentUser.id = userId;
    users.insert(0, currentUser);
    return users;
  }

  Future<bool> checkAudioPermissions() async {
    if (Platform.isIOS) {
      return true;
    }

    bool isGranted = await _permissionManager.checkPermissionsForAudioCall();
    if (isGranted) {
      return isGranted;
    }
    _showError("The requested permissions are required for the application to function correctly.");
    return isGranted;
  }

  Future<bool> checkVideoPermissions() async {
    if (Platform.isIOS) {
      return true;
    }

    bool isGranted = await _permissionManager.checkPermissionsForVideoCall();
    if (isGranted) {
      return isGranted;
    }
    _showError("The requested permissions are required for the application to function correctly.");
    return isGranted;
  }

  void clearSelectedUsers() {
    var copyOfSelectedUsersSet = Set<UserEntity>.from(selectedUsersSet);

    for (var element in copyOfSelectedUsersSet) {
      _unselectUser(element);
    }
  }

  Future<void> _initWebRTC() async {
    try {
      hideError();
      await _callManager.initAndSubscribeEvents();
    } on PlatformException catch (e) {
      showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> _subscribeCall() async {
    try {
      await _callManager.subscribeCall(_callSubscription);
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> _unsubscribeCall() async {
    try {
      await _callManager.unsubscribeCall(_callSubscription);
    } on PlatformException catch (e) {
      _showError(ErrorParser.parseFrom(e));
    }
  }

  Future<void> setDefaultStateForGettingCall() async {
    receivedCall = false;
    notifyListeners();
  }

  Future<List<QBUser?>?> loadOpponents() async {
    List<int>? opponentsIds = await _callManager.getOpponentIdsFromCall();

    try {
      int currentUserId = await _storageManager.getLoggedUserId();
      opponentsIds?.remove(currentUserId);
      List<QBUser?> users = await _usersManager.getUsersByIds(opponentsIds);
      return users;
    } on PlatformException catch (e) {
      hideUsersLoading();
      _showError(ErrorParser.parseFrom(e));
    }
    return null;
  }

  Future<List<QBUser?>?> loadCallUsers() async {
    List<int>? opponentsIds = await _callManager.getOpponentIdsFromCall();

    try {
      int currentUserId = await _storageManager.getLoggedUserId();

      List<QBUser?> users = await _usersManager.getUsersByIds(opponentsIds);
      QBUser? currentUser = users.firstWhere((element) => element?.id == currentUserId);
      users.remove(currentUser);
      users.insert(0, currentUser);
      return users;
    } on PlatformException catch (e) {
      hideUsersLoading();
      _showError(ErrorParser.parseFrom(e));
    }
    return null;
  }

  Future<void> loadUsers() async {
    hideError();
    if (!loadNextUsers) {
      _currentPage = 1;
    }
    showUsersLoading();
    notifyListeners();

    QBSort sort = QBSort();
    sort.field = QBUsersSortFields.UPDATED_AT;
    sort.type = QBUsersSortTypes.STRING;
    sort.ascending = false;

    try {
      List<QBUser?> users = await _usersManager.getUsers(_currentPage, PAGE_SIZE, sort: sort);

      _usersEntitiesFrom(users);

      hideUsersLoading();
      _currentPage++;
      notifyListeners();
    } on PlatformException catch (e) {
      hideUsersLoading();
      _showError(ErrorParser.parseFrom(e));
    }
  }

  void showUsersLoading() {
    if (_currentPage == 1) {
      loadedUsersSet.clear();
      usersLoading = true;
    } else {
      loadNextUsers = true;
    }
  }

  void hideUsersLoading() {
    if (_currentPage == 1) {
      usersLoading = false;
    } else {
      loadNextUsers = false;
    }
  }

  void _usersEntitiesFrom(List<QBUser?> users) async {
    int currentUserId = await _storageManager.getLoggedUserId();
    for (final user in users) {
      if (user?.id != currentUserId) {
        loadedUsersSet.add(UserEntity(false, user));
      }
    }

    for (final selectedUser in selectedUsersSet) {
      if (loadedUsersSet.contains(selectedUser) && selectedUser.userId != null) {
        _getLoadedUser(selectedUser.userId!)?.selected = true;
      }
    }
  }

  void searchUsers(String text) async {
    hideError();
    if (!searchNextUsers) {
      _currentSearchPage = 1;
    }

    showUsersSearching();
    notifyListeners();

    QBFilter filter = QBFilter();
    filter.field = QBUsersFilterFields.FULL_NAME;
    filter.operator = QBUsersFilterOperators.IN;
    filter.type = QBUsersFilterTypes.STRING;
    filter.value = text;

    try {
      List<QBUser?> users =
          await _usersManager.getUsers(_currentSearchPage, PAGE_SIZE, filter: filter);
      _usersEntitiesFrom(users);

      hideUsersSearching();
      _currentSearchPage++;
      notifyListeners();
    } on PlatformException catch (e) {
      hideUsersSearching();
      showError(ErrorParser.parseFrom(e));
    }
  }

  void showUsersSearching() {
    if (_currentSearchPage == 1) {
      loadedUsersSet.clear();
      usersLoading = true;
    } else {
      loadNextUsers = true;
    }
  }

  void hideUsersSearching() {
    if (_currentSearchPage == 1) {
      usersLoading = false;
    } else {
      loadNextUsers = false;
    }
  }

  void handleChangedSelectedUsers(bool remove, UserEntity userWrapper) {
    hideError();

    if (selectedUsersSet.length == 3 && !remove) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => showError("Cannot select more than 3 users"),
      );
      return;
    }

    if (remove) {
      _unselectUser(userWrapper);
    } else {
      _selectUser(userWrapper);
    }
    _prepareSelectedUsersIds();
  }

  void _prepareSelectedUsersIds() {
    List<int> selectedUsersIds = [];
    for (var element in selectedUsersSet) {
      if (element.userId != null) {
        selectedUsersIds.add(element.userId!);
      }
    }
    notifyListeners();
  }

  void _unselectUser(UserEntity userWrapper) {
    if (selectedUsersSet.contains(userWrapper)) {
      selectedUsersSet.remove(userWrapper);
    }
    if (loadedUsersSet.contains(userWrapper) && userWrapper.userId != null) {
      UserEntity? loadedUser = _getLoadedUser(userWrapper.userId!);
      loadedUser?.selected = false;
    }
  }

  void _selectUser(UserEntity userWrapper) {
    if (!selectedUsersSet.contains(userWrapper)) {
      selectedUsersSet.add(userWrapper);
    }
    if (loadedUsersSet.contains(userWrapper) && userWrapper.userId != null) {
      UserEntity? loadedUser = _getLoadedUser(userWrapper.userId!);
      loadedUser?.selected = true;
    }
  }

  UserEntity? _getLoadedUser(int id) {
    for (final userWrapper in loadedUsersSet) {
      if (userWrapper.userId == id) {
        return userWrapper;
      }
    }
    return null;
  }

  Future<void> logout() async {
    try {
      hideError();
      isLoggingOut = true;
      notifyListeners();
      await _authManager.logout();
      await _storageManager.cleanCredentials();
      isLoggedIn = false;
      isLoggingOut = false;
      notifyListeners();
    } on PlatformException catch (e) {
      isLoggingOut = false;
      _showError(ErrorParser.parseFrom(e));
    }
  }

  void _showError(String errorMessage) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showError(errorMessage);
    });
  }

  CallSubscription _createCallSubscription() {
    return CallSubscriptionImpl(
        tag: "UsersScreenViewModel",
        onIncomingCall: (session) {
          if (session?.type == QBRTCSessionTypes.VIDEO) {
            isVideoCall = true;
          } else {
            isVideoCall = false;
          }
          receivedCall = true;
          notifyListeners();
        },
        onError: (errorMessage) {
          _showError(errorMessage);
        });
  }
}
