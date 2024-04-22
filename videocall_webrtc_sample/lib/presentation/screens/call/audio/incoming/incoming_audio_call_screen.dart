import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/audio/incoming/widgets/controls_incom_audio_buttons.dart';

import '../../../../utils/notification_utils.dart';
import '../../widgets/user_avatars.dart';
import '../../widgets/user_names.dart';
import '../audio_call/audio_call_screen.dart';
import 'incoming_audio_call_screen_view_model.dart';

class IncomingAudioCallScreen extends StatefulWidget {
  final List<QBUser?> opponents;

  const IncomingAudioCallScreen({super.key, required this.opponents});

  static show(
    BuildContext context, {
    required List<QBUser?> opponents,
  }) {
    return Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => IncomingAudioCallScreen(
                  opponents: opponents,
                )));
  }

  @override
  State<IncomingAudioCallScreen> createState() => _IncomingAudioCallScreenState();
}

class _IncomingAudioCallScreenState extends State<IncomingAudioCallScreen> {
  final IncomingAudioCallScreenViewModel _viewModel = IncomingAudioCallScreenViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.init(widget.opponents);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: ChangeNotifierProvider(
        create: (context) => _viewModel,
        child: Scaffold(
            backgroundColor: const Color(0xFF414E5B),
            body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              UserAvatars(opponentsLength: _viewModel.opponents!.length),
              UserNames(users: _viewModel.opponents!),
              SizedBox(height: MediaQuery.of(context).size.height / 2 - 104),
              ControlsIncomeAudioButtons(
                onAccept: () => _viewModel.acceptCall(),
                onReject: () => _viewModel.rejectCall(),
              ),
              Selector<IncomingAudioCallScreenViewModel, bool>(
                selector: (_, viewModel) => viewModel.isCallEnd,
                builder: (_, isCallEnd, __) {
                  if (isCallEnd) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pop();
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),
              Selector<IncomingAudioCallScreenViewModel, bool>(
                selector: (_, viewModel) => viewModel.callAccepted,
                builder: (_, callAccepted, __) {
                  if (callAccepted) {
                    _removeCurrentScreenAndShowAudioCallScreen();
                  }
                  return const SizedBox.shrink();
                },
              ),
              Selector<IncomingAudioCallScreenViewModel, bool>(
                selector: (_, viewModel) => viewModel.callRejected,
                builder: (_, callRejected, __) {
                  if (callRejected) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pop();
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),
              Selector<IncomingAudioCallScreenViewModel, String?>(
                  selector: (_, viewModel) => viewModel.errorMessage,
                  builder: (_, errorMessage, __) {
                    if (errorMessage?.isNotEmpty ?? false) {
                      _showErrorSnackbar(errorMessage!, context);
                    }
                    return const SizedBox.shrink();
                  }),
            ]))));
  }

  Future<void> _removeCurrentScreenAndShowAudioCallScreen() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      List<QBUser?> opponents = _viewModel.opponents!;
      AudioCallScreen.show(context, true, opponents);
    });
  }

  void _showErrorSnackbar(String errorMessage, BuildContext context,
      {VoidCallback? errorCallback}) {
    return NotificationUtils.showSnackBarError(context, errorMessage, errorCallback: errorCallback);
  }
}
