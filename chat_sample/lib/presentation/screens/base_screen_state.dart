import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../bloc/base_bloc.dart';

abstract class BaseScreenState<T extends Bloc> extends State<StatefulWidget>
    with WidgetsBindingObserver {
  T? _bloc;

  T? get bloc => _bloc;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _bloc?.onForegroundMode();
        break;
      case AppLifecycleState.paused:
        _bloc?.onBackgroundMode();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void initBloc(BuildContext context) {
    _bloc = Provider.of<T>(context, listen: false);
    _bloc?.init();
  }
}
