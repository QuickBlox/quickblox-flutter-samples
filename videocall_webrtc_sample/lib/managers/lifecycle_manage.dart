import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:videocall_webrtc_sample/managers/call_manager.dart';
import 'package:videocall_webrtc_sample/managers/reject_call_manager.dart';
import 'package:videocall_webrtc_sample/managers/storage_manager.dart';

import '../dependency/dependency_impl.dart';
import 'chat_manager.dart';

class LifecycleManager with WidgetsBindingObserver {
  final ChatManager _chatManager = DependencyImpl.getInstance().getChatManager();
  final StorageManager _storageManager = DependencyImpl.getInstance().getStorageManager();
  final CallManager _callManager = DependencyImpl.getInstance().getCallManager();

  bool _isForeground = false;

  bool get isForeground => _isForeground;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
        RejectCallManager.stop();

        try {
          bool isExistSavedUser = await _storageManager.isExistSavedUser();
          bool isNotConnectedToChat = await _isNotConnectedToChat();
          if (isExistSavedUser && isNotConnectedToChat) {
            await _connectToChat();
            await _callManager.initAndSubscribeEvents();
          }
        } on PlatformException catch (e) {
          //TODO: Need to add logic of show exception to screen.
          log('Error occurred: $e', error: e);
        }
        break;
      case AppLifecycleState.detached:
        _isForeground = false;
        try {
          bool isHasActiveCall = _callManager.isActiveCall();
          if (isHasActiveCall) {
            _callManager.hangUpCall();
          }
          _callManager.release();
          _chatManager.disconnect();
        } on PlatformException catch (e) {
          log('Error occurred: $e', error: e);
        }
        break;
      case AppLifecycleState.hidden:
        _isForeground = false;
        try {
          bool isNotHasActiveCall = !_callManager.isActiveCall();
          if (isNotHasActiveCall) {
            _callManager.release();
            _chatManager.disconnect();
          }
        } on PlatformException catch (e) {
          log('Error occurred: $e', error: e);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        break;
    }
  }

  void setIsForeground(bool isForeground) async {
    _isForeground = isForeground;
  }

  Future<bool> _isNotConnectedToChat() async {
    bool isConnectedToChat = await _chatManager.isConnected() ?? false;
    bool isNotConnectedToChat = !isConnectedToChat;
    return isNotConnectedToChat;
  }

  Future<void> _connectToChat() async {
    final userId = await _storageManager.getLoggedUserId();
    final userPassword = await _storageManager.getUserPassword();
    await _chatManager.connect(userId, userPassword);
  }
}
