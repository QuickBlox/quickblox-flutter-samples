import 'package:chat_sample/bloc/login/login_screen_bloc.dart';
import 'package:chat_sample/bloc/login/login_screen_events.dart';
import 'package:flutter/material.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class UserNameTextField extends StatelessWidget {
  UserNameTextField({Key? key, this.textField, this.loginBloc}) : super(key: key);

  final TextField? textField;
  final LoginScreenBloc? loginBloc;
  final TextEditingController txtController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextField(
        controller: txtController,
        onChanged: (userName) {
          if (userName.contains('  ')) {
            userName = userName.replaceAll('  ', ' ');
            txtController
              ..text = userName
              ..selection = TextSelection.collapsed(offset: userName.length);
          } else {
            loginBloc?.events?.add(ChangedUsernameFieldEvent(userName));
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
