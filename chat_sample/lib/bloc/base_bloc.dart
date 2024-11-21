import 'package:chat_sample/data/device_repository.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

abstract class BaseBloc<A> {
  void init();

  void setArgs(A args);

  void dispose();
}

class Bloc<E, S, A> implements BaseBloc<A> {
  final DeviceRepository _deviceRepository = DeviceRepository();

  PublishSubject<E>? _eventController;
  PublishSubject<S>? _stateController;

  Sink<E>? get events => _eventController;

  PublishSubject<S>? get states => _stateController;

  void init() async {
    _deviceRepository.subscribeConnectionStatus();

    _eventController = PublishSubject<E>();
    _stateController = PublishSubject<S>();

    _eventController?.listen(onReceiveEvent);
  }

  void setArgs(A args) {}

  Future<bool> checkInternetConnection() async {
    bool isExistInternetConnection = true;

    ConnectionType connectionType = await _deviceRepository.checkInternetConnection();
    if (connectionType == ConnectionType.none) {
      isExistInternetConnection = false;
    }
    return isExistInternetConnection;
  }

  void dispose() {
    _eventController?.close();
    _stateController?.close();
  }

  void onBackgroundMode() async {
    _deviceRepository.unsubscribeConnectionStatus();
  }

  void onForegroundMode() async {
    _deviceRepository.subscribeConnectionStatus();
  }

  void onReceiveEvent(E receivedEvent) {}

  String makeErrorMessage(PlatformException? e) {
    String message = e?.message ?? "";
    String code = e?.code ?? "";
    return code + " : " + message;
  }
}
