import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _obscurePassword = true;

  static const Color _primaryBlue = Color(0xFF57A0D3);
  static const Color _darkBlue = Color(0xFF1F2C46);

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final email = await _authService.getSavedEmail();
    if (email != null) {
      setState(() {
        _emailController.text = email;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final statusCode = result['statusCode'] ?? 0;
    final body = result['body'] as Map<String, dynamic>? ?? {};

    if (statusCode == 200) {
      setState(() {
        _isLoading = false;
      });
      widget.onLoginSuccess();
      return;
    }

    setState(() {
      _isLoading = false;
      _message = body['message'] ?? 'Login gagal (kode $statusCode).';
    });
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      prefixIconColor: _primaryBlue,
      filled: true,
      fillColor: isDark ? theme.colorScheme.surface : const Color(0xFFF5F8FE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.4),
      ),
      labelStyle: TextStyle(
        color: onSurface.withOpacity(isDark ? 0.7 : 0.6),
        fontSize: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final Color titleColor = isDark ? onSurface : _darkBlue;
    final Color subtitleColor =
        isDark ? onSurface.withOpacity(0.7) : Colors.grey.shade700;

    // =============== OPSI 1 ===============
    // DARK MODE = FULL SOLID COLOR
    // LIGHT MODE = GRADIENT
    final BoxDecoration backgroundDecoration = isDark
        ? BoxDecoration(
            color: theme.scaffoldBackgroundColor,
          )
        : const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFe8f4fb),
                Color(0xFFc3ddf3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          );

    final Color cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: backgroundDecoration,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ================= LOGO ==================
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? theme.cardColor : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/kasir.png',
                          height: 70,
                          width: 70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Kasir Resto Pintar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola transaksi & laporan usaha dengan mudah',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ================= ERROR MESSAGE ==================
                  if (_message != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _message!.toLowerCase().contains('berhasil')
                            ? const Color(0xFFE8F8EF)
                            : const Color(0xFFFFE8E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _message!.toLowerCase().contains('berhasil')
                              ? const Color(0xFF46A36A)
                              : const Color(0xFFD64545),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _message!.toLowerCase().contains('berhasil')
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            size: 18,
                            color: _message!.toLowerCase().contains('berhasil')
                                ? const Color(0xFF46A36A)
                                : const Color(0xFFD64545),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _message!.toLowerCase().contains('berhasil')
                                    ? const Color(0xFF2F7A4E)
                                    : const Color(0xFFB93636),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ================= CARD LOGIN ==================
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white.withOpacity(0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 22,
                          spreadRadius: 2,
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Masuk ke akun kasir',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Gunakan email yang sudah diverifikasi admin.',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtitleColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              label: 'Email kasir',
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Email wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20,
                                  color: subtitleColor,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Password wajib diisi' : null,
                          ),

                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Lupa password? Hubungi admin',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtitleColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tombol login
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.primary),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            _primaryBlue,
                                            Color(0xFF3C82B2),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Masuk Sekarang',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Link daftar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun kasir?',
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
