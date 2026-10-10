import 'dart:async';

import 'package:flutter/material.dart';

import '../Screens/auth/auth_routes.dart';
import 'auth_session_service.dart';
import 'user_service.dart';

class AuthSessionLifecycle extends StatefulWidget {
  const AuthSessionLifecycle({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AuthSessionLifecycle> createState() => _AuthSessionLifecycleState();
}

class _AuthSessionLifecycleState extends State<AuthSessionLifecycle>
    with WidgetsBindingObserver {
  final UserService _userService = UserService();
  Timer? _inactivityTimer;
  Timer? _refreshTimer;
  DateTime? _lastActivityAt;
  bool _hadSession = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthSessionService.session.addListener(_sessionChanged);
    _hadSession = AuthSessionService.current != null;
    if (_hadSession) _startSessionTimers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthSessionService.session.removeListener(_sessionChanged);
    _cancelTimers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        AuthSessionService.current == null) {
      return;
    }

    final lastActivityAt = _lastActivityAt;
    if (lastActivityAt != null &&
        DateTime.now().difference(lastActivityAt) >=
            AuthSessionService.inactivityDuration) {
      unawaited(_endSession());
      return;
    }
    _recordActivity();
  }

  void _sessionChanged() {
    final activeSession = AuthSessionService.current;
    if (activeSession == null) {
      _cancelTimers();
      if (_hadSession) _openLogin();
      _hadSession = false;
      return;
    }

    final isNewLogin = !_hadSession;
    _hadSession = true;
    if (isNewLogin) {
      _startSessionTimers();
    } else {
      // Rotating a token is not user activity and must not reset inactivity.
      _scheduleTokenRefresh();
    }
  }

  void _startSessionTimers({bool resetActivity = true}) {
    if (resetActivity) _lastActivityAt = DateTime.now();
    _resetInactivityTimer();
    _scheduleTokenRefresh();
  }

  void _recordActivity() {
    if (AuthSessionService.current == null) return;
    _lastActivityAt = DateTime.now();
    _resetInactivityTimer();

    final session = AuthSessionService.current!;
    if (session.accessTokenExpiresAt.difference(DateTime.now()) <=
        const Duration(minutes: 5)) {
      unawaited(_refreshAccessToken());
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (AuthSessionService.current == null) return;
    _inactivityTimer = Timer(
      AuthSessionService.inactivityDuration,
      _endSession,
    );
  }

  void _scheduleTokenRefresh({Duration? retryAfter}) {
    _refreshTimer?.cancel();
    final session = AuthSessionService.current;
    if (session == null) return;

    final refreshIn =
        retryAfter ??
        session.accessTokenExpiresAt
            .subtract(const Duration(minutes: 1))
            .difference(DateTime.now());
    _refreshTimer = Timer(
      refreshIn.isNegative ? Duration.zero : refreshIn,
      _refreshAccessToken,
    );
  }

  Future<void> _refreshAccessToken() async {
    final currentSession = AuthSessionService.current;
    if (currentSession == null || _refreshing) return;
    if (!currentSession.refreshTokenExpiresAt.isAfter(DateTime.now())) {
      await _endSession();
      return;
    }

    _refreshing = true;
    try {
      final response = await _userService.refreshSession(
        currentSession.refreshToken,
      );
      if (!identical(AuthSessionService.current, currentSession)) return;
      await AuthSessionService.activate(currentSession.refreshed(response));
    } on UserServiceException catch (error) {
      if (error.statusCode == 401) {
        await _endSession();
      } else {
        _scheduleTokenRefresh(retryAfter: const Duration(minutes: 1));
      }
    } catch (_) {
      // Being offline must not log the user out. Retry when activity resumes.
      _scheduleTokenRefresh(retryAfter: const Duration(minutes: 1));
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _endSession() async {
    final refreshToken = AuthSessionService.current?.refreshToken;
    await AuthSessionService.clear();
    if (refreshToken == null) return;
    try {
      await _userService.logout(refreshToken);
    } catch (_) {
      // Local logout remains immediate when the device is offline.
    }
  }

  void _openLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AuthRoutes.login,
        (route) => false,
      );
    });
  }

  void _cancelTimers() {
    _inactivityTimer?.cancel();
    _refreshTimer?.cancel();
    _inactivityTimer = null;
    _refreshTimer = null;
    _lastActivityAt = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _recordActivity(),
      onPointerMove: (_) => _recordActivity(),
      onPointerSignal: (_) => _recordActivity(),
      child: Focus(
        onKeyEvent: (_, __) {
          _recordActivity();
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }
}
