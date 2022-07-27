import 'package:chat_sample/bloc/app_info/app_info_screen_bloc.dart';
import 'package:chat_sample/bloc/app_info/app_info_screen_states.dart';
import 'package:chat_sample/bloc/stream_builder_with_listener.dart';
import 'package:chat_sample/presentation/screens/base_screen_state.dart';
import 'package:chat_sample/presentation/utils/notification_utils.dart';
import 'package:chat_sample/presentation/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quickblox_sdk/models/qb_settings.dart';

import 'app_info_screen_item.dart';

/// Created by Injoit in 2021.
/// Copyright © 2021 Quickblox. All rights reserved.

class AppInfoScreen extends StatefulWidget {
  @override
  _AppInfoScreenState createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends BaseScreenState<AppInfoScreenBloc> {
  @override
  Widget build(BuildContext context) {
    initBloc(context);

    return Scaffold(
      appBar: AppBar(title: Text('App Info'), backgroundColor: Color(0xff3978fc)),
      body: new Padding(
        padding: new EdgeInsets.only(left: 15, right: 15),
        child: StreamBuilderWithListener<AppInfoScreenStates>(
          stream: bloc?.states?.stream as Stream<AppInfoScreenStates>,
          listener: (state) {
            if (state is SettingsErrorState) {
              NotificationBarUtils.showSnackBarError(this.context, state.error);
            }
          },
          builder: (context, state) {
            if (state.data is SettingsInProgressState) {
              return Progress(Alignment.center);
            }
            if (state.data is SettingsSuccessState) {
              QBSettings? settings = (state.data as SettingsSuccessState).settings;

              String version = (state.data as SettingsSuccessState).version;
              String? sdkVersion = settings?.sdkVersion;
              String? appId = settings?.appId;
              String? authKey = settings?.authKey;
              String? authSecret = settings?.authSecret;
              String? accountKey = settings?.accountKey;
              String? apiEndpoint = settings?.apiEndpoint;
              String? chatEndpoint = settings?.chatEndpoint;

              return ListView(
                children: <Widget>[
                  AppInfoScreenItem('Application version', version),
                  AppInfoScreenItem('Quickblox SDK version', sdkVersion),
                  AppInfoScreenItem('Application Id', appId),
                  AppInfoScreenItem('Authorization key', authKey),
                  AppInfoScreenItem('Authorization secret', authSecret),
                  AppInfoScreenItem('Account key', accountKey),
                  AppInfoScreenItem('API domain', apiEndpoint),
                  AppInfoScreenItem('Chat domain', chatEndpoint),
                  Padding(
                      padding: EdgeInsets.only(top: 27),
                      child: Container(
                          height: 30,
                          child: SvgPicture.asset('assets/icons/logo_info.svg',
                              fit: BoxFit.fitHeight)))
                ],
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
