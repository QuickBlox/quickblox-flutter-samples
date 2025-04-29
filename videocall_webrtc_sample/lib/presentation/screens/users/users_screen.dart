import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickblox_sdk/models/qb_user.dart';
import 'package:videocall_webrtc_sample/entities/user_entity.dart';
import 'package:videocall_webrtc_sample/presentation/dialogs/yes_no_dialog.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/audio/audio_call/audio_call_screen.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/audio/incoming/incoming_audio_call_screen.dart';
import 'package:videocall_webrtc_sample/presentation/screens/call/video/video_call/video_call_screen.dart';
import 'package:videocall_webrtc_sample/presentation/screens/login/login_screen.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/callback/app_bar_callback.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/callback/app_bar_callback_impl.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/users_screen_view_model.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/widgets/users_app_bar.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/widgets/users_list_item.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/widgets/users_list_loading_item.dart';
import 'package:videocall_webrtc_sample/presentation/screens/users/widgets/users_search_bar.dart';
import 'package:videocall_webrtc_sample/presentation/screens/widgets/decorated_app_bar.dart';
import 'package:videocall_webrtc_sample/presentation/utils/debouncer.dart';

import '../../../entities/push_notification_entity.dart';
import '../../../managers/callkit_manager.dart';
import '../../utils/notification_utils.dart';
import '../call/video/incoming/incoming_video_call_screen.dart';

class UsersScreen extends StatefulWidget {
  static show(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
  }

  static showAndClearStack(BuildContext context) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UsersScreen()), (_) => false);
  }

  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UsersScreenViewModel _viewModel = UsersScreenViewModel();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final _searchDebouncer = Debouncer();
  bool _search = false;

  @override
  void initState() {
    super.initState();
    _viewModel.init();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    double? maxScroll = _scrollController.position.maxScrollExtent;
    double? currentScroll = _scrollController.position.pixels;
    if (maxScroll == currentScroll) {
      if (_search) {
        _viewModel.searchNextUsers = true;
        _viewModel.searchUsers(_searchController.text.trim());
      } else {
        _viewModel.loadNextUsers = true;
        _viewModel.loadUsers();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  AppBarCallback createAppBarCallback() {
    return AppBarCallbackImpl(onLogIn: () {
      _showLoginScreen();
    }, onLogOut: () {
      _showLogoutDialog();
    }, onAudioCall: () async {
      List<QBUser> selectedUsers = _viewModel.getSelectedQbUsers();

      if (selectedUsers.isEmpty) {
        _showErrorSnackbar("To make a call you need to select at least one opponent.", context);
        return;
      }

      await _viewModel.checkAudioPermissions();
      await _viewModel.startAudioCallAndSendPushIfNeed();
      setState(() {
        _viewModel.clearSelectedUsers();
      });
      _showAudioCallScreen(selectedUsers);
    }, onVideoCall: () async {
      List<QBUser> selectedUsers = _viewModel.getSelectedQbUsers();

      if (selectedUsers.isEmpty) {
        _showErrorSnackbar("To make a call you need to select at least one opponent.", context);
        return;
      }

      await _viewModel.checkVideoPermissions();

      List<QBUser?> users = await _viewModel.addCurrentUserToList(selectedUsers);
      await _viewModel.addVideoCallEntities(users);
      setState(() {
        _viewModel.clearSelectedUsers();
      });
      _showVideoCallScreen(selectedUsers);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _search = false;
      _viewModel.loadNextUsers = false;
      _viewModel.loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UsersScreenViewModel>(
      create: (context) => _viewModel,
      child: Scaffold(
          appBar: DecoratedAppBar(appBar: UsersAppBar(callback: createAppBarCallback())),
          body: Column(
            children: [
              UsersSearchBar(
                searchController: _searchController,
                callback: (text) {
                  if (text.length >= 3) {
                    _search = true;
                    _viewModel.searchNextUsers = false;
                    _searchDebouncer.call(() => _viewModel.searchUsers(text));
                  }
                  if (text.isEmpty) {
                    _search = false;
                    _viewModel.loadNextUsers = false;
                    _viewModel.loadUsers();
                  }
                },
              ),
              Selector<UsersScreenViewModel, bool>(
                selector: (_, viewModel) => viewModel.usersLoading,
                builder: (_, isLoading, __) {
                  return isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : const SizedBox.shrink();
                },
              ),
              Expanded(
                child: Selector<UsersScreenViewModel, List<UserEntity>>(
                  selector: (_, viewModel) => viewModel.loadedUsersSet.toList(),
                  builder: (_, qbUsers, __) {
                    return qbUsers.isEmpty
                        ? const SizedBox.shrink()
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView.builder(
                              addAutomaticKeepAlives: true,
                              controller: _scrollController,
                              itemCount: qbUsers.length,
                              itemBuilder: (_, index) {
                                if (index == qbUsers.length - 1) {
                                  return Column(
                                    children: [
                                      UsersListItem(qbUsers[index], _viewModel.handleChangedSelectedUsers),
                                      const UsersListLoadingItem(),
                                    ],
                                  );
                                }
                                return UsersListItem(qbUsers[index], _viewModel.handleChangedSelectedUsers);
                              },
                            ));
                  },
                ),
              ),
              Selector<UsersScreenViewModel, String?>(
                  selector: (_, viewModel) => viewModel.errorMessage,
                  builder: (_, errorMessage, __) {
                    if (errorMessage?.isNotEmpty ?? false) {
                      _showErrorSnackbar(errorMessage!, context);
                    }
                    return const SizedBox.shrink();
                  }),
              Selector<UsersScreenViewModel, bool>(
                  selector: (_, viewModel) => viewModel.receivedCall,
                  builder: (_, isGettingCall, __) {
                    if (isGettingCall) {
                      if (_viewModel.isVideoCall) {
                        _checkVideoPermissionsAndShowCallKit();
                      } else {
                        _checkAudioPermissionsAndShowCallKit();
                      }
                    }
                    return const SizedBox.shrink();
                  }),
              Selector<UsersScreenViewModel, PushNotificationEntity?>(
                  selector: (_, viewModel) => viewModel.entity,
                  builder: (_, entity, __) {
                    if (entity != null) {
                      // bool isFromBackground = entity.senderId == null && entity.senderName == null;
                      // bool isForeground = DependencyImpl.getInstance().getLifecycleManager().isForeground;

                      if (_viewModel.isVideoCall) {
                        _showIncomingVideoCallScreen(_viewModel.opponents);
                      } else {
                        _showIncomingAudioCallScreen(_viewModel.opponents);
                      }
                    }

                    return const SizedBox.shrink();
                  }),
            ],
          )),
    );
  }

  void _showLogoutDialog() {
    return YesNoDialog(
            onPressedPrimary: () async {
              Navigator.pop(context);
              await _viewModel.logout();
            },
            onPressedSecondary: () => Navigator.pop(context),
            primaryButtonText: 'Logout',
            secondaryButtonText: 'Cancel')
        .show(context, title: 'Press Logout to continue', dismissTouchOutside: true);
  }

  void _showErrorSnackbar(String errorMessage, BuildContext context) {
    return NotificationUtils.showSnackBarError(context, errorMessage);
  }

  void _showLoginScreen() {
    NotificationUtils.hideSnackBar(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoginScreen.showAndClearStack(context);
    });
  }

  void _showAudioCallScreen(List<QBUser> users) {
    NotificationUtils.hideSnackBar(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioCallScreen.showAndClearStack(context, false, users);
      _viewModel.setReceivedCall(false);
    });
  }

  void _showVideoCallScreen(List<QBUser> users) {
    NotificationUtils.hideSnackBar(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      VideoCallScreen.showAndClearStack(context, false, users);
      _viewModel.setReceivedCall(false);
    });
  }

  void _showIncomingAudioCallScreen(List<QBUser> opponents) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      IncomingAudioCallScreen.showAndClearStack(context, opponents: opponents);
      _viewModel.setReceivedCall(false);
    });
  }

  void _showIncomingVideoCallScreen(List<QBUser> opponents) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      IncomingVideoCallScreen.showAndClearStack(context, opponents);
      _viewModel.setReceivedCall(false);
    });
  }

  void _showCallKit(bool isVideoCall) {
    PushNotificationEntity? entity = PushNotificationEntity(
        conferenceType: isVideoCall ? ConferenceType.VIDEO : ConferenceType.AUDIO, opponents: _viewModel.opponents);

    String sessionId = _viewModel.getCallSessionId();
    CallkitManager.showIncomingCall(jsonEncode(entity.toJson()), _viewModel.opponents, isVideoCall, true, sessionId,
        _viewModel.callerId.toString());
    _viewModel.setReceivedCall(false);
    _viewModel.callerId = null;
  }

  void _checkVideoPermissionsAndShowCallKit() {
    _viewModel.checkVideoPermissions().then((value) {
      if (value) {
        _showCallKit(_viewModel.isVideoCall);
      }
    });
  }

  void _checkAudioPermissionsAndShowCallKit() {
    _viewModel.checkAudioPermissions().then((value) {
      if (value) {
        _showCallKit(_viewModel.isVideoCall);
      }
    });
  }
}
