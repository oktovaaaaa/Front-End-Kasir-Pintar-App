import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const KasirRestoApp());
}

class KasirRestoApp extends StatefulWidget {
  const KasirRestoApp({super.key});

  @override
  State<KasirRestoApp> createState() => _KasirRestoAppState();
}

class _KasirRestoAppState extends State<KasirRestoApp> {
  final AuthService _authService = AuthService();
  Widget _defaultPage = const Scaffold(body: Center(child: CircularProgressIndicator()));

  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _authService.getToken();
    setState(() {
      if (token != null) {
        _defaultPage = HomePage(onUserActivity: _resetInactivityTimer, onForceLogout: _forceLogout);
        _startInactivityTimer();
      } else {
        _defaultPage = LoginPage(onLoginSuccess: _onLoginSuccess);
      }
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _defaultPage = HomePage(onUserActivity: _resetInactivityTimer, onForceLogout: _forceLogout);
    });
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 30), () async {
      await _forceLogout();
    });
  }

  void _resetInactivityTimer() {
    if (_inactivityTimer != null && _inactivityTimer!.isActive) {
      _inactivityTimer!.cancel();
    }
    _startInactivityTimer();
  }

  Future<void> _forceLogout() async {
    await _authService.logout();
    _inactivityTimer?.cancel();

    setState(() {
      _defaultPage = LoginPage(onLoginSuccess: _onLoginSuccess);
    });
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector global untuk deteksi aktivitas user
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _defaultPage,
      ),
    );
  }
}
