import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/models/qb_custom_object.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/credentials.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';
import 'package:quickblox_sdk_example/widgets/blue_app_bar.dart';
import 'package:quickblox_sdk_example/widgets/blue_button.dart';

class CustomObjectsScreen extends StatefulWidget {
  static show(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => CustomObjectsScreen()));
  }

  @override
  State<StatefulWidget> createState() => _CustomObjectsScreenState();
}

class _CustomObjectsScreenState extends State<CustomObjectsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: BlueAppBar('Custom Objects'),
        body: Center(
            child: Column(children: [
          BlueButton('create one', () => createOne()),
          BlueButton('create multiple', () => createMultiple()),
          BlueButton('remove', () => remove()),
          BlueButton('get by ids', () => getByIds()),
          BlueButton('get all', () => getAll()),
          BlueButton('update one', () => updateOne()),
          BlueButton('update multiple', () => updateMultiple())
        ])));
  }

  Future<void> createOne() async {
    Map<String, Object> fieldsMap = Map();
    fieldsMap['testString'] = "testFiled";
    fieldsMap['testInteger'] = 123;
    fieldsMap['testBoolean'] = true;

    try {
      List<QBCustomObject?> customObjectsList =
          await QB.data.create(className: CUSTOM_OBJECT_ClASS_NAME, fields: fieldsMap);
      QBCustomObject? customObject = customObjectsList[0];

      if (customObject != null) {
        _id = customObject.id;
        SnackBarUtils.showResult(_scaffoldKey, "The class $CUSTOM_OBJECT_ClASS_NAME  was created \n ID: $_id");
      }
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> createMultiple() async {
    Map<String, Object> fieldsMap = Map();
    fieldsMap['testString'] = "testFiled";
    fieldsMap['testInteger'] = 123;
    fieldsMap['testBoolean'] = true;

    try {
      List<QBCustomObject?> customObjectsList =
          await QB.data.create(className: CUSTOM_OBJECT_ClASS_NAME, objects: [fieldsMap]);
      QBCustomObject? customObject = customObjectsList[0];

      if (customObject != null) {
        _id = customObject.id;
        SnackBarUtils.showResult(_scaffoldKey, "The class $CUSTOM_OBJECT_ClASS_NAME  was created \n ID: $_id");
      }
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> remove() async {
    try {
      await QB.data.remove(CUSTOM_OBJECT_ClASS_NAME, [_id!]);
      SnackBarUtils.showResult(_scaffoldKey, "The ids: $_id were removed");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getByIds() async {
    try {
      List<QBCustomObject?> customObjects = await QB.data.getByIds(CUSTOM_OBJECT_ClASS_NAME, [_id!]);
      int size = customObjects.length;
      SnackBarUtils.showResult(_scaffoldKey, "Loaded custom objects size: $size");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getAll() async {
    try {
      List<QBCustomObject?> customObjects = await QB.data.get(CUSTOM_OBJECT_ClASS_NAME);
      int size = customObjects.length;
      if (size > 0) {
        _id = customObjects[0]?.id;
      }
      SnackBarUtils.showResult(_scaffoldKey, "Loaded custom objects size: $size");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> updateOne() async {
    try {
      Map<String, Object> fieldsMap = Map();
      fieldsMap['testString'] = "UpdatedOneTestString";
      fieldsMap['testInteger'] = 888;
      fieldsMap['testBoolean'] = false;

      List<QBCustomObject?> customObject = await QB.data.update(CUSTOM_OBJECT_ClASS_NAME, id: _id!, fields: fieldsMap);
      String? id = customObject[0]!.id;
      SnackBarUtils.showResult(_scaffoldKey, "The custom object $id was updated");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> updateMultiple() async {
    try {
      Map<String, Object> fields = Map();
      fields['testString'] = "UpdatedMultipleTestString";
      fields['testInteger'] = 888;
      fields['testBoolean'] = false;

      Map<String, Object> object = Map();
      object["id"] = _id!;
      object["fields"] = fields;

      List<QBCustomObject?> customObjects = await QB.data.update(CUSTOM_OBJECT_ClASS_NAME, id: _id!, objects: [object]);
      String? id = customObjects[0]!.id;
      SnackBarUtils.showResult(_scaffoldKey, "The custom object $id was updated");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }
}
