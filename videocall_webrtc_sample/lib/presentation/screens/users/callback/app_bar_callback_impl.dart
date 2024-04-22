import 'app_bar_callback.dart';

class AppBarCallbackImpl implements AppBarCallback {
  AppBarCallbackImpl({
    required void Function() onLogIn,
    required void Function() onLogOut,
    required void Function() onVideoCall,
    required void Function() onAudioCall,
  })   : _onLogIn = onLogIn,
        _onLogOut = onLogOut,
        _onVideoCall = onVideoCall,
        _onAudioCall = onAudioCall;

  final void Function() _onLogIn;
  final void Function() _onLogOut;
  final void Function() _onVideoCall;
  final void Function() _onAudioCall;

  @override
  void onLogIn() => _onLogIn();

  @override
  void onLogOut() => _onLogOut();

  @override
  void onVideoCall() => _onVideoCall();

  @override
  void onAudioCall() => _onAudioCall();
}
