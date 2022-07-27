import 'package:flutter/material.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class AppInfoScreenItem extends StatelessWidget {
  const AppInfoScreenItem(this.title, this.value, {Key? key}) : super(key: key);

  final String? title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: new EdgeInsets.only(top: 16),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title ?? "not loaded" ,
              style: new TextStyle(
                fontSize: 13,
                color: Color(0xff6c7a92),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Padding(
              padding: new EdgeInsets.only(top: 5, bottom: 11),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value ?? "not loaded",
                  style: new TextStyle(fontSize: 17),
                ),
              ))
        ],
      ),
    );
  }
}
