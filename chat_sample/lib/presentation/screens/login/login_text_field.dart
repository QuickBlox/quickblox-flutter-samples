import 'package:chat_sample/bloc/login/login_screen_bloc.dart';
import 'package:chat_sample/bloc/login/login_screen_events.dart';
import 'package:flutter/material.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class LoginTextField extends StatelessWidget {
  LoginTextField({Key? key, this.textField, this.loginBloc}) : super(key: key);

  final TextField? textField;
  final LoginScreenBloc? loginBloc;
  final TextEditingController txtController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextField(
        controller: txtController,
        onChanged: (login) {
          if (login.contains(' ')) {
            login = login.replaceAll(' ', '');
            txtController
              ..text = login
              ..selection = TextSelection.collapsed(offset: login.length);
          } else {
            loginBloc?.events?.add(ChangedLoginFieldEvent(login));
          }
        },
        style: new TextStyle(fontSize: 17.0),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: new BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      ),
      decoration: BoxDecoration(
        boxShadow: [
          new BoxShadow(
              color: Color.fromARGB(255, 217, 229, 255), offset: new Offset(0, 6), blurRadius: 11.0)
        ],
      ),
    );
  }
}
