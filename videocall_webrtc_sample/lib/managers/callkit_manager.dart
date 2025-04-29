import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:uuid/uuid.dart';
import 'package:videocall_webrtc_sample/managers/chat_manager.dart';
import 'package:videocall_webrtc_sample/managers/reject_call_manager.dart';
import 'package:videocall_webrtc_sample/managers/storage_manager.dart';

import '../dependency/dependency_impl.dart';
import '../entities/push_notification_entity.dart';
import 'callback/call_subscription_impl.dart';

class CallkitManager {
  static final CallkitManager _instance = CallkitManager._internal();

  CallkitManager._internal();

  factory CallkitManager() {
    return _instance;
  }

  static final HashMap<String, Function(PushNotificationEntity?)> _acceptCallListeners = HashMap();
  static final HashMap<String, Function(String? sessionId)> _rejectCallListeners = HashMap();

  static Future<void> init() async {
    _subscribeCallkitEvents();
  }

  static void subscribeToClickAcceptCall(String screenId, Function(PushNotificationEntity?) listener) {
    _acceptCallListeners[screenId] = listener;
  }

  static void unsubscribeAcceptCall(String screenId) {
    _acceptCallListeners.remove(screenId);
  }

  static void subscribeToClickRejectCall(String screenId, Function(String? sessionId) listener) {
    _rejectCallListeners[screenId] = listener;
  }

  static void unsubscribeRejectCall(String screenId) {
    _rejectCallListeners.remove(screenId);
  }

  static void _notifyAcceptedCall(PushNotificationEntity? message) {
    for (var listener in _acceptCallListeners.values) {
      listener(message);
    }
  }

  static void _notifyRejectedCall(String? sessionId) {
    for (var listener in _rejectCallListeners.values) {
      listener(sessionId);
    }
  }

  static Future<void> showIncomingCall(
    String? jsonMessage,
    List<QBUser?> callUsers,
    bool isVideoCall,
    bool isFromForeground,
    String? sessionId,
    String? callerId,
  ) async {
    CallKitParams params =
        _buildCallkitParams(jsonMessage, callUsers, isVideoCall, isFromForeground, sessionId, callerId);
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static CallKitParams _buildCallkitParams(
    String? jsonMessage,
    List<QBUser?> callUsers,
    bool isVideoCall,
    bool isFromForeground,
    String? sessionId,
    String? callerId,
  ) {
    return CallKitParams(
      id: sessionId,
      nameCaller: _buildPluralityUsersNames(callUsers),
      appName: 'QuickBlox',
      handle: 'call',
      type: isVideoCall ? 1 : 0,
      extra: <String, dynamic>{'message': jsonMessage, 'isFromForeground': isFromForeground, 'callerId': callerId},
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      android: _buildAndroidParams(),
      ios: _buildIOSParams(),
    );
  }

  static AndroidParams _buildAndroidParams() {
    return const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#414E5B',
      actionColor: '#4CAF50',
      textColor: '#ffffff',
      incomingCallNotificationChannelName: 'Incoming Call',
      isShowFullLockedScreen: false,
      isImportant: true,
      isBot: false,
    );
  }

  static IOSParams _buildIOSParams() {
    return const IOSParams(
      iconName: 'QuickBlox',
      handleType: '',
      supportsVideo: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    );
  }

  static String _buildPluralityUsersNames(List<QBUser?> callUsers) {
    if (callUsers.isEmpty) {
      return 'Unknown';
    }

    if (callUsers.length == 1) {
      return callUsers[0]?.fullName ?? 'Unknown';
    }

    String other = callUsers.length - 1 == 2 ? "other" : "others";

    if (callUsers.length - 1 > 1) {
      return '${callUsers[0]?.fullName} and ${callUsers.length - 2} $other';
    } else {
      return callUsers[0]?.fullName ?? 'Unknown';
    }
  }

  static Future<void> showOutgoingCall(List<QBUser?> callUsers, bool isVideoCall) async {
    final params = CallKitParams(
      id: Uuid().v4(),
      appName: 'QuickBlox',
      nameCaller: _buildPluralityUsersNames(callUsers),
      handle: 'call',
      type: isVideoCall ? 1 : 0,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      ios: _buildIOSParams(),
    );

    await FlutterCallkitIncoming.startCall(params);
  }

  static bool _isExist(String? value) {
    return value != null && value.isNotEmpty;
  }

  static bool _isNotExist(String? value) {
    return !_isExist(value);
  }

  static void _subscribeCallkitEvents() {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event?.event == Event.actionCallAccept) {
        String? jsonMessage = _parseJsonFromEvent(event!);

        PushNotificationEntity? notificationEntity;

        if (_isExist(jsonMessage)) {
          notificationEntity = PushNotificationEntity.fromString(jsonMessage!);
        } else {
          ConferenceType conferenceType = event.body['type'] == 1 ? ConferenceType.VIDEO : ConferenceType.AUDIO;
          notificationEntity = PushNotificationEntity(conferenceType: conferenceType);
        }

        _notifyAcceptedCall(notificationEntity);
      } else if (event?.event == Event.actionCallDecline) {
        final StorageManager storageManager = DependencyImpl.getInstance().getStorageManager();

        String? login = await storageManager.getNameLogin();
        String? password = await storageManager.getUserPassword();

        int userId = await storageManager.getLoggedUserId();
        bool isNotCorrectUserId = userId <= 0;

        RootIsolateToken? firebaseIsolateToken = RootIsolateToken.instance;

        String? jsonMessage = _parseJsonFromEvent(event!);
        if (_isNotExist(jsonMessage) ||
            _isNotExist(login) ||
            _isNotExist(password) ||
            isNotCorrectUserId ||
            firebaseIsolateToken == null) {
          return;
        }

        PushNotificationEntity? notificationEntity = PushNotificationEntity.fromString(jsonMessage!);

        bool isForeground = DependencyImpl.getInstance().getLifecycleManager().isForeground;
        if (isForeground) {
          _notifyRejectedCall(notificationEntity.sessionId);
          return;
        }

        if (Platform.isAndroid) {
          return;
        }

        RejectCallManager.start(
          login,
          password,
          userId,
          firebaseIsolateToken,
          notificationEntity.sessionId,
          rejectWaitingSeconds: 6,
        );
      } else if (event?.event == Event.actionCallIncoming) {
        bool isForeground = DependencyImpl.getInstance().getLifecycleManager().isForeground;
        if (Platform.isAndroid || isForeground) {
          return;
        }

        final StorageManager storageManager = DependencyImpl.getInstance().getStorageManager();

        String? login = await storageManager.getNameLogin();
        String? password = await storageManager.getUserPassword();

        int userId = await storageManager.getLoggedUserId();
        bool isNotCorrectUserId = userId <= 0;

        RootIsolateToken? firebaseIsolateToken = RootIsolateToken.instance;

        String? jsonMessage = _parseJsonFromEvent(event!);
        if (_isNotExist(jsonMessage) ||
            _isNotExist(login) ||
            _isNotExist(password) ||
            isNotCorrectUserId ||
            firebaseIsolateToken == null) {
          return;
        }

        PushNotificationEntity? notificationEntity = PushNotificationEntity.fromString(jsonMessage!);

        RejectCallManager.initQb(login, password, userId, notificationEntity.sessionId, firebaseIsolateToken);
      }else if (event?.event == Event.actionCallEnded) {
        bool isForeground = DependencyImpl.getInstance().getLifecycleManager().isForeground;
        if (Platform.isAndroid || isForeground) {
          return;
        }
        final StorageManager storageManager = DependencyImpl.getInstance().getStorageManager();

        String? login = await storageManager.getNameLogin();
        String? password = await storageManager.getUserPassword();

        int userId = await storageManager.getLoggedUserId();
        bool isNotCorrectUserId = userId <= 0;

        RootIsolateToken? firebaseIsolateToken = RootIsolateToken.instance;

        String? jsonMessage = _parseJsonFromEvent(event!);
        if (_isNotExist(jsonMessage) ||
            _isNotExist(login) ||
            _isNotExist(password) ||
            isNotCorrectUserId ||
            firebaseIsolateToken == null) {
          return;
        }

        PushNotificationEntity? notificationEntity = PushNotificationEntity.fromString(jsonMessage!);

        RejectCallManager.start(
          login,
          password,
          userId,
          firebaseIsolateToken,
          notificationEntity.sessionId,
          rejectWaitingSeconds: 6,
        );
      }
    });
  }

  static String? _parseJsonFromEvent(CallEvent event) {
    dynamic message = event.body['extra']['message'];

    if (message is Map<Object?, Object?>) {
      return jsonEncode(message);
    } else if (message is String) {
      return message;
    }

    return null;
  }

  static Future<bool?> isVideoCall() async {
    PushNotificationEntity? entity = await _getActiveNotificationEntity();
    if (entity == null || entity.conferenceType == null) {
      return null;
    }

    return entity.conferenceType == ConferenceType.VIDEO;
  }

  static Future<List<QBUser>?> getOpponentsFromEntity() async {
    PushNotificationEntity? entity = await _getActiveNotificationEntity();
    if (entity == null || entity.opponents == null) {
      return null;
    }

    return entity.opponents;
  }

  static Future<PushNotificationEntity?> _getActiveNotificationEntity() async {
    var calls = await FlutterCallkitIncoming.activeCalls();

    if (calls is List && calls.isNotEmpty) {
      final Map<String, dynamic> call = Map<String, dynamic>.from(calls[0] as Map);
      final Map<String, dynamic> extra = Map<String, dynamic>.from(call['extra'] as Map);

      final String? message = extra['message'] as String?;
      if (_isExist(message)) {
        return PushNotificationEntity.fromString(message!);
      }
    }
    return null;
  }

  static Future<bool> isActiveCallKit() async {
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List && calls.isEmpty) {
      return false;
    }
    return true;
  }

  static Future<String> getApnsVoipToken() async {
    return await FlutterCallkitIncoming.getDevicePushTokenVoIP();
  }

  static Future<void> endAllCallsInCallkit() async {
    await FlutterCallkitIncoming.endAllCalls();
  }

  static void handleRejectEvent(String? sessionId, RootIsolateToken? firebaseIsolateToken) async {
    await DependencyImpl.getInstance().init();

    final ChatManager chatManager = DependencyImpl.getInstance().getChatManager();
    bool? isConnected = await chatManager.isConnected();

    if (isConnected == true) {
      _notifyRejectedCall(null);
      return;
    }

    final StorageManager storageManager = DependencyImpl.getInstance().getStorageManager();

    String? login = await storageManager.getNameLogin();
    String? password = await storageManager.getUserPassword();

    int userId = await storageManager.getLoggedUserId();
    bool isNotCorrectUserId = userId <= 0;

    if (_isNotExist(login) ||
        _isNotExist(password) ||
        _isNotExist(sessionId) ||
        isNotCorrectUserId ||
        firebaseIsolateToken == null) {
      print('login, password or userId is not exist');
      FlutterCallkitIncoming.onEvent.listen(null);
      return;
    }

    RejectCallManager.initQb(login, password, userId, sessionId, firebaseIsolateToken);

    DependencyImpl.getInstance().getCallManager().subscribeCall(CallSubscriptionImpl(
          tag: "handleRejectEvent",
          onCallEnd: () async {
            FlutterCallkitIncoming.endAllCalls();
            FlutterCallkitIncoming.onEvent.listen(null);

            await Future.delayed(Duration(seconds: 1), () async {
              try {
                DependencyImpl.getInstance().getChatManager().disconnect();
              } on PlatformException catch (e) {
                print('log: Error occurred: $e');
              }
            });
          },
        ));

    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event?.event == Event.actionCallDecline) {
        RejectCallManager.startWithIsolate(login, password, userId, firebaseIsolateToken, sessionId,
            rejectWaitingSeconds: 15);

        FlutterCallkitIncoming.onEvent.listen(null);
      }
    });
  }
}
