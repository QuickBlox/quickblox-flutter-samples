import 'package:videocall_webrtc_sample/dependency/dependency_exception.dart';
import 'package:videocall_webrtc_sample/managers/auth_manager.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';
import 'package:videocall_webrtc_sample/managers/chat_manager.dart';
import 'package:videocall_webrtc_sample/managers/push_notification_manager.dart';
import 'package:videocall_webrtc_sample/managers/ringtone_manager.dart';
import 'package:videocall_webrtc_sample/managers/settings_manager.dart';
import 'package:videocall_webrtc_sample/managers/storage_manager.dart';
import 'package:videocall_webrtc_sample/managers/users_manager.dart';

import '../managers/lifecycle_manage.dart';
import '../managers/permission_manager.dart';
import 'dependency.dart';

class DependencyImpl implements Dependency {
  DependencyImpl._();

  static DependencyImpl? _instance;

  static DependencyImpl getInstance() {
    return _instance ??= DependencyImpl._();
  }

  static AuthManager? _authManager;
  static ChatManager? _chatManager;
  static SettingsManager? _settingsManager;
  static StorageManager? _storageManager;
  static UsersManager? _usersManager;
  static CallManager? _callManager;
  static PermissionManager? _permissionManager;
  static RingtoneManager? _ringtoneManager;
  static PushNotificationManager? _pushNotificationManager;
  static LifecycleManager? _lifecycleManager;

  @override
  Future<void> init() async {
    _authManager = AuthManager();
    _chatManager = ChatManager();
    _settingsManager = SettingsManager();
    _storageManager = StorageManager();
    await _storageManager?.init();

    _pushNotificationManager = PushNotificationManager();
    _usersManager = UsersManager();
    _callManager = CallManager();
    _permissionManager = PermissionManager();
    _ringtoneManager = RingtoneManager();
    _lifecycleManager = LifecycleManager();
  }

  void _throwDIException(String text) {
    throw DependencyException("The $text is not initialized. First, you need to init dependency.");
  }

  @override
  AuthManager getAuthManager() {
    if (_authManager == null) {
      _throwDIException("AuthManager");
    }
    return _authManager!;
  }

  @override
  ChatManager getChatManager() {
    if (_chatManager == null) {
      _throwDIException("ChatManager");
    }
    return _chatManager!;
  }

  @override
  SettingsManager getSettingsManager() {
    if (_settingsManager == null) {
      _throwDIException("SettingsManager");
    }
    return _settingsManager!;
  }

  @override
  StorageManager getStorageManager() {
    if (_storageManager == null) {
      _throwDIException("StorageManager");
    }
    return _storageManager!;
  }

  @override
  UsersManager getUsersManager() {
    if (_usersManager == null) {
      _throwDIException("UsersManager");
    }
    return _usersManager!;
  }

  @override
  CallManager getCallManager() {
    if (_callManager == null) {
      _throwDIException("CallManager");
    }
    return _callManager!;
  }

  @override
  PermissionManager getPermissionManager() {
    if (_permissionManager == null) {
      _throwDIException("PermissionManager");
    }
    return _permissionManager!;
  }

  @override
  RingtoneManager getRingtoneManager() {
    if (_ringtoneManager == null) {
      _throwDIException("RingtoneManager");
    }
    return _ringtoneManager!;
  }

  @override
  LifecycleManager getLifecycleManager() {
    if (_lifecycleManager == null) {
      _throwDIException("LifecycleManager");
    }
    return _lifecycleManager!;
  }

  @override
  void setAuthManager(AuthManager authManager) {
    _authManager = authManager;
  }

  @override
  void setChatManager(ChatManager chatManager) {
    _chatManager = chatManager;
  }

  @override
  void setPermissionManager(PermissionManager permissionManager) {
    _permissionManager = permissionManager;
  }

  @override
  void setRingtoneManager(RingtoneManager ringtoneManager) {
    _ringtoneManager = ringtoneManager;
  }

  @override
  void setSettingsManager(SettingsManager settingsManager) {
    _settingsManager = settingsManager;
  }

  @override
  void setStorageManager(StorageManager storageManager) {
    _storageManager = storageManager;
  }

  @override
  void setUsersManager(UsersManager usersManager) {
    _usersManager = usersManager;
  }

  @override
  void setWebRTCManager(CallManager callManager) {
    _callManager = callManager;
  }

  @override
  PushNotificationManager getPushNotificationManager() {
    return _pushNotificationManager!;
  }

  @override
  void setPushNotificationManager(PushNotificationManager pushNotificationManager) {
    _pushNotificationManager = pushNotificationManager;
  }

  @override
  void setLifecycleManager(LifecycleManager lifecycleManager) {
    _lifecycleManager = lifecycleManager;
  }
}
