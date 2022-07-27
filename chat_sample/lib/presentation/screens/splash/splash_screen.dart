import 'dart:async';

import 'package:chat_sample/presentation/screens/base_screen_state.dart';
import 'package:chat_sample/bloc/splash/splash_screen_bloc.dart';
import 'package:chat_sample/bloc/splash/splash_screen_events.dart';
import 'package:chat_sample/bloc/splash/splash_screen_states.dart';
import 'package:chat_sample/bloc/stream_builder_with_listener.dart';
import 'package:chat_sample/presentation/navigation/navigation_service.dart';
import 'package:chat_sample/presentation/navigation/router.dart';
import 'package:chat_sample/presentation/utils/notification_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends BaseScreenState<SplashScreenBloc> {
  @override
  Widget build(BuildContext context) {
    initBloc(context);
    bloc?.events?.add(AuthEvent());

    return Scaffold(
      body: new Container(
        color: Color(0xff3978fc),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(child: SvgPicture.asset('assets/icons/qb-logo.svg')),
            StreamBuilderWithListener<SplashScreenStates>(
              listener: (state) {
                if (state is NeedLoginState) {
                  NavigationService().pushReplacementNamed(LoginScreenRoute);
                }
                if (state is LoginSuccessState) {
                  NavigationService().pushReplacementNamed(DialogsScreenRoute);
                }
                if (state is AuthenticationErrorState) {
                  NotificationBarUtils.showSnackBarError(context, state.error, errorCallback: () {
                    bloc?.events?.add(AuthEvent());
                  });
                }
              },
              stream: bloc?.states?.stream as Stream<SplashScreenStates>,
              builder: (context, state) {
                if (state.data is LoginInProgressState) {
                  return Container(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 150),
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 4.0),
                      ));
                }
                return Text("");
              },
            ),
            Container(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Text('Flutter Chat Sample',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ))
          ],
        ),
      ),
    );
  }
}
