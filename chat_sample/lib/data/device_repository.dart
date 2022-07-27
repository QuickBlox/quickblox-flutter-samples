import 'dart:async';
import 'dart:collection';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class DeviceRepository {
  static final DeviceRepository _deviceRepository = DeviceRepository._instance();

  factory DeviceRepository() {
    return _deviceRepository;
  }

  DeviceRepository._instance();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Set<ConnectionListener> _connectionListenersSet = HashSet<ConnectionListener>();

  void subscribeConnectionStatus() {
    if (_connectivitySubscription == null) {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
        _notifyListeners(_getConnectionType(result));
      });
    }
  }

  void unsubscribeConnectionStatus() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  Future<ConnectionType> checkInternetConnection() async {
    ConnectivityResult result = ConnectivityResult.none;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      throw PlatformException(code: e.code, message: e.message);
    }
    return _getConnectionType(result);
  }

  ConnectionType _getConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.none:
        return ConnectionType.none;
      default:
        return ConnectionType.none;
    }
  }

  void addConnectionListener<T extends ConnectionListener>(T listener) {
    listener.setConnectionListenerTag(listener.toString());
    _connectionListenersSet.add(listener);
  }

  void removeConnectionListener(ConnectionListener listener) {
    _connectionListenersSet.remove(listener);
  }

  void _notifyListeners(ConnectionType type) {
    _connectionListenersSet.forEach((element) {
      element.connectionTypeChanged(type);
    });
  }
}

class ConnectionListener {
  String? tag;

  void setConnectionListenerTag(String tag) {
    this.tag = tag;
  }

  void connectionTypeChanged(ConnectionType type) {}

  @override
  int get hashCode {
    int hash = 3;
    hash = 53 * hash + tag.toString().length;
    return hash;
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionListener && other.runtimeType == runtimeType && other.tag == tag;
  }
}

enum ConnectionType { wifi, mobile, none }
