import 'package:flutter/material.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  Future<void>? pushNamed(String routeName) {
    return navigatorKey.currentState?.pushNamed(routeName);
  }

  Future<void>? pushReplacementNamed(String routeName) {
    return navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void pop() {
    return navigatorKey.currentState?.pop();
  }
}
