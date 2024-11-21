import 'package:chat_sample/bloc/login/login_screen_bloc.dart';
import 'package:chat_sample/bloc/login/login_screen_events.dart';
import 'package:chat_sample/bloc/login/login_screen_states.dart';
import 'package:chat_sample/bloc/stream_builder_with_listener.dart';
import 'package:chat_sample/presentation/navigation/navigation_service.dart';
import 'package:chat_sample/presentation/navigation/router.dart';
import 'package:chat_sample/presentation/screens/base_screen_state.dart';
import 'package:chat_sample/presentation/screens/login/user_name_text_field.dart';
import 'package:chat_sample/presentation/utils/notification_utils.dart';
import 'package:chat_sample/presentation/widgets/decorated_app_bar.dart';
import 'package:chat_sample/presentation/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'login_text_field.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends BaseScreenState<LoginScreenBloc> {
  LoginTextField? _loginTextField;
  UserNameTextField? _userNameTextField;

  @override
  Widget build(BuildContext context) {
    initBloc(context);

    _loginTextField = LoginTextField(loginBloc: bloc as LoginScreenBloc);
    _userNameTextField = UserNameTextField(loginBloc: bloc as LoginScreenBloc);

    return Scaffold(
      appBar: DecoratedAppBar(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Enter to chat'),
          backgroundColor: Color(0xff3978fc),
          leading: Container(),
          actions: <Widget>[
            IconButton(
                icon: SvgPicture.asset('assets/icons/info.svg'),
                onPressed: () {
                  NavigationService().pushNamed(AppInfoScreenRoute);
                })
          ],
        ),
      ),
      body: Container(
        child: ListView(
          padding: EdgeInsets.only(left: 16, right: 16),
          children: [
            Container(
              padding: EdgeInsets.only(top: 28),
              child: Text(
                'Please enter your login \n and display name',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
            ),
            Container(
                padding: EdgeInsets.only(top: 28),
                child: Text('Login', style: TextStyle(color: Color(0x85333333), fontSize: 13))),
            Container(
              padding: EdgeInsets.only(top: 11),
              child: this._loginTextField,
            ),
            StreamProvider<LoginScreenStates>(
                create: (context) => bloc?.states?.stream as Stream<LoginScreenStates>,
                initialData: LoginFieldValidState(),
                child: Selector<LoginScreenStates, LoginScreenStates>(
                  selector: (_, state) => state,
                  shouldRebuild: (previous, next) {
                    return next is LoginFieldInvalidState ||
                        next is LoginFieldValidState ||
                        next is AllowLoginState;
                  },
                  builder: (_, state, __) {
                    if (state is LoginFieldInvalidState) {
                      return Container(
                          padding: EdgeInsets.only(top: 11),
                          child: Text(
                              "Use your email or alphanumeric characters in a range from 3 to 50. First character must be a letter.",
                              style: new TextStyle(color: Color.fromRGBO(153, 169, 198, 1.0))));
                    }
                    return Text("");
                  },
                )),
            Container(
                padding: EdgeInsets.only(top: 16),
                child:
                    Text('Username', style: new TextStyle(color: Color(0x85333333), fontSize: 13))),
            Container(
              padding: EdgeInsets.only(top: 11),
              child: this._userNameTextField,
            ),
            StreamProvider<LoginScreenStates>(
                create: (context) => bloc?.states?.stream as Stream<LoginScreenStates>,
                initialData: UserNameFieldValidState(),
                child: Selector<LoginScreenStates, LoginScreenStates>(
                    selector: (_, state) => state,
                    shouldRebuild: (previous, next) {
                      return next is UserNameFieldInvalidState ||
                          next is UserNameFieldValidState ||
                          next is AllowLoginState;
                    },
                    builder: (_, state, __) {
                      if (state is UserNameFieldInvalidState) {
                        return Container(
                            padding: EdgeInsets.only(top: 11),
                            child: Text(
                                "Use alphanumeric characters and spaces in a range from 3 to 20. Cannot contain more than one space in a row.",
                                style: new TextStyle(color: Color.fromRGBO(153, 169, 198, 1.0))));
                      }
                      return Text("");
                    })),
            Container(
                padding: EdgeInsets.only(top: 42, left: 64, right: 64),
                child: StreamBuilderWithListener<LoginScreenStates>(
                  stream: bloc?.states?.stream as Stream<LoginScreenStates>,
                  listener: (state) {
                    if (state is LoginSuccessState) {
                      NavigationService().pushReplacementNamed(DialogsScreenRoute);
                    }
                    if (state is LoginErrorState) {
                      NotificationBarUtils.showSnackBarError(this.context, state.error);
                    }
                  },
                  builder: (context, state) {
                    if (state.data is LoginInProgressState) {
                      return Progress(Alignment.center);
                    }
                    return TextButton(
                        onPressed: state.data is AllowLoginState || state.data is LoginErrorState
                            ? () {
                                bloc?.events?.add(LoginPressedEvent());
                                FocusScope.of(context).unfocus();
                              }
                            : null,
                        style: ButtonStyle(
                          elevation: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.disabled) ? null : 3),
                          shadowColor: WidgetStateProperty.resolveWith((states) =>
                              states.contains(WidgetState.disabled)
                                  ? Color(0xff99A9C6)
                                  : Color(0x403978FC)),
                          backgroundColor: WidgetStateProperty.resolveWith((states) =>
                              states.contains(WidgetState.disabled)
                                  ? Color(0xff99A9C6)
                                  : Color(0xff3978FC)),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.only(top: 12, bottom: 12),
                          child: Text(
                            'Login',
                            style: TextStyle(fontSize: 17, color: Colors.white),
                          ),
                        ));
                  },
                ))
          ],
        ),
      ),
    );
  }
}
