import 'dart:async';
import 'package:flutter/material.dart';

import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const KasirRestoApp());
}



class KasirRestoApp extends StatefulWidget {
  const KasirRestoApp({super.key});

  @override
  State<KasirRestoApp> createState() => _KasirRestoAppState();
}

class _KasirRestoAppState extends State<KasirRestoApp> {
  final AuthService _authService = AuthService();

  /// Halaman yang sedang aktif
  Widget _defaultPage =
      const Scaffold(body: Center(child: CircularProgressIndicator()));

  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// Setiap app baru dibuka lagi (setelah di-kill dari recent), kita:
  /// 1) paksa logout (hapus token)
  /// 2) tampilkan OnboardingPage
  Future<void> _initApp() async {
    // Pastikan token / sesi lama dibersihkan
    await _authService.logout();

    setState(() {
      // APP SELALU MULAI DARI ONBOARDING -> LOGIN
      _defaultPage = OnboardingPage(onContinue: _goToLogin);
    });
  }

  /// Pindah ke halaman login
  void _goToLogin() {
    setState(() {
      _defaultPage = LoginPage(onLoginSuccess: _onLoginSuccess);
    });
  }

  /// Dipanggil ketika login BERHASIL (statusCode == 200 di LoginPage)
  void _onLoginSuccess() {
    setState(() {
      _defaultPage = HomePage(
        onUserActivity: _resetInactivityTimer,
        onForceLogout: _forceLogout,
      );
    });
    _startInactivityTimer();
  }

  /// Mulai timer auto logout 30 menit
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 30), () async {
      await _forceLogout();
    });
  }

  /// Reset timer ketika ada aktivitas user (tap / geser)
  void _resetInactivityTimer() {
    if (_inactivityTimer != null && _inactivityTimer!.isActive) {
      _inactivityTimer!.cancel();
    }
    _startInactivityTimer();
  }

  /// Paksa logout -> hapus token + kembali ke login
  Future<void> _forceLogout() async {
    await _authService.logout();
    _inactivityTimer?.cancel();

    setState(() {
      _defaultPage = LoginPage(onLoginSuccess: _onLoginSuccess);
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector global untuk deteksi aktivitas user di seluruh app
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
