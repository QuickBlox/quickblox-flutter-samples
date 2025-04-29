import 'package:videocall_webrtc_sample/managers/push_notification_manager.dart';

import '../managers/auth_manager.dart';
import '../managers/call_manager.dart';
import '../managers/chat_manager.dart';
import '../managers/lifecycle_manage.dart';
import '../managers/permission_manager.dart';
import '../managers/ringtone_manager.dart';
import '../managers/settings_manager.dart';
import '../managers/storage_manager.dart';
import '../managers/users_manager.dart';

abstract class Dependency {
  void init();

  AuthManager getAuthManager();

  ChatManager getChatManager();

  SettingsManager getSettingsManager();

  StorageManager getStorageManager();

  UsersManager getUsersManager();

  CallManager getCallManager();

  PermissionManager getPermissionManager();

  RingtoneManager getRingtoneManager();

  PushNotificationManager getPushNotificationManager();

  LifecycleManager getLifecycleManager();

  void setAuthManager(AuthManager authManager);

  void setChatManager(ChatManager chatManager);

  void setSettingsManager(SettingsManager settingsManager);

  void setStorageManager(StorageManager storageManager);

  void setUsersManager(UsersManager usersManager);

  void setWebRTCManager(CallManager webRTCManager);

  void setPermissionManager(PermissionManager permissionManager);

  void setRingtoneManager(RingtoneManager ringtoneManager);

  void setPushNotificationManager(PushNotificationManager pushNotificationManager);

  void setLifecycleManager(LifecycleManager lifecycleManager);
}
