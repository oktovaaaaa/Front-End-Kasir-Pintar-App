import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';

const String kThemePreferenceKey = 'kasir_resto_is_dark_mode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // 👇 BACA THEME TERAKHIR SEBELUM runApp
  final prefs = await SharedPreferences.getInstance();
  final bool isDarkSaved = prefs.getBool(kThemePreferenceKey) ?? false;

  runApp(KasirRestoApp(initialIsDarkMode: isDarkSaved));
}

class KasirRestoApp extends StatefulWidget {
  final bool initialIsDarkMode;

  const KasirRestoApp({
    super.key,
    required this.initialIsDarkMode,
  });

  @override
  State<KasirRestoApp> createState() => _KasirRestoAppState();
}

class _KasirRestoAppState extends State<KasirRestoApp> {
  final AuthService _authService = AuthService();

  /// Halaman yang sedang aktif
  Widget _defaultPage =
      const Scaffold(body: Center(child: CircularProgressIndicator()));

  Timer? _inactivityTimer;

  /// state untuk tema (di-control dari HomePage)
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();

    // pake nilai awal dari main()
    _isDarkMode = widget.initialIsDarkMode;

    _initApp();
  }

  /// Simpan nilai tema ke SharedPreferences
  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kThemePreferenceKey, isDark);
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

  /// Helper untuk membangun HomePage sesuai state tema terbaru
  Widget _buildHomePage() {
    return HomePage(
      onUserActivity: _resetInactivityTimer,
      onForceLogout: _forceLogout,
      isDarkMode: _isDarkMode,
      onThemeChanged: (bool isDark) {
        setState(() {
          _isDarkMode = isDark;
          // rebuild HomePage dengan nilai tema yang baru
          _defaultPage = _buildHomePage();
        });
        // simpan pilihan tema ke local storage
        _saveTheme(isDark);
      },
    );
  }

  /// Dipanggil ketika login BERHASIL (statusCode == 200 di LoginPage)
  void _onLoginSuccess() {
    setState(() {
      _defaultPage = _buildHomePage();
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

        // === KUNCI DARK MODE DI SINI ===
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

        // THEME TERANG
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF57A0D3),
          scaffoldBackgroundColor: const Color(0xFFF6F8FF),
          cardColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF57A0D3),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),

        // THEME GELAP
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF57A0D3),
          scaffoldBackgroundColor: const Color(0xFF020617),
          cardColor: const Color(0xFF0F172A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF57A0D3),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),

        home: _defaultPage,
      ),
    );
  }
}
