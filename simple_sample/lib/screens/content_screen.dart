import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickblox_sdk/file/constants.dart';
import 'package:quickblox_sdk/models/qb_file.dart';
import 'package:quickblox_sdk/quickblox_sdk.dart';
import 'package:quickblox_sdk_example/utils/dialog_utils.dart';
import 'package:quickblox_sdk_example/utils/snackbar_utils.dart';
import 'package:quickblox_sdk_example/widgets/blue_app_bar.dart';
import 'package:quickblox_sdk_example/widgets/blue_button.dart';

class ContentScreen extends StatefulWidget {
  static show(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ContentScreen()));
  }

  @override
  State<StatefulWidget> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _fileUrl;
  String? _fileUid;
  int? _fileId;

  StreamSubscription? _uploadProgressSubscription;

  @override
  void dispose() {
    super.dispose();
    unsubscribeUpload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: BlueAppBar('File'),
        body: Center(
            child: Column(children: [
          BlueButton('subscribe upload progres', () => subscribeUpload()),
          BlueButton('unsubscribe upload progress', () => unsubscribeUpload()),
          BlueButton('upload', () => upload()),
          BlueButton('pick file', () => pickFile()),
          BlueButton('get info', () => getInfo()),
          BlueButton('get public URL', () => getPublicURL()),
          BlueButton('get private URL', () => getPrivateURL())
        ])));
  }

  Future<void> subscribeUpload() async {
    if (_uploadProgressSubscription != null) {
      SnackBarUtils.showResult(
          _scaffoldKey, "You already have a subscription: " + QBFileUploadProgress.FILE_UPLOAD_PROGRESS);
      return;
    }

    try {
      _uploadProgressSubscription =
          await QB.content.subscribeUploadProgress(_fileUrl!, QBFileUploadProgress.FILE_UPLOAD_PROGRESS, (data) {
        String progress = data["payload"]["progress"].toString();
        String url = data["payload"]["url"];
        SnackBarUtils.showResult(_scaffoldKey, "Progress value is: $progress \n for url $url");
      });
      SnackBarUtils.showResult(_scaffoldKey, "Subscripbed: " + QBFileUploadProgress.FILE_UPLOAD_PROGRESS);
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  void unsubscribeUpload() async {
    _uploadProgressSubscription?.cancel();
    _uploadProgressSubscription = null;
  }

  Future<void> upload() async {
    try {
      QBFile? file = await QB.content.upload(_fileUrl!, public: true);
      _fileId = file!.id;
      _fileUid = file.uid;
      SnackBarUtils.showResult(_scaffoldKey, "The file $_fileId was uploaded");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      _fileUrl = file.path;
    } else {
      // User canceled the picker
    }
  }

  Future<void> getInfo() async {
    try {
      QBFile? file = await QB.content.getInfo(_fileId!);
      int? id = file!.id;
      SnackBarUtils.showResult(_scaffoldKey, "The file $id was loaded");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getPublicURL() async {
    try {
      String? url = await QB.content.getPublicURL(_fileUid!);
      SnackBarUtils.showResult(_scaffoldKey, "Url $url was loaded");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }

  Future<void> getPrivateURL() async {
    try {
      String? url = await QB.content.getPrivateURL(_fileUid!);
      SnackBarUtils.showResult(_scaffoldKey, "Url $url was loaded");
    } on PlatformException catch (e) {
      DialogUtils.showError(context, e);
    }
  }
}
