import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  String? _message;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // FOTO PROFIL (OPSIONAL)
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  static const Color _primaryBlue = Color(0xFF57A0D3);
  static const Color _darkBlue = Color(0xFF1F2C46);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color fillColor =
        isDark ? const Color(0xFF020617) : const Color(0xFFF5F8FE);

    final Color labelColor =
        isDark ? Colors.white70 : Colors.grey.shade600;

    final Color enabledBorderColor =
        isDark ? const Color(0xFF4B5563) : Colors.transparent;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      prefixIconColor: _primaryBlue,
      filled: true,
      fillColor: fillColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: enabledBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.4),
      ),
      labelStyle: TextStyle(
        color: labelColor,
        fontSize: 13,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  void _showPickImageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: _primaryBlue,
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: _primaryBlue,
                  ),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Hapus foto (kosongkan)',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _pickedImage = null;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _authService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmController.text,
      // profileImagePath: _pickedImage?.path,
    );

    final statusCode = result['statusCode'] ?? 0;
    final body = result['body'] as Map<String, dynamic>? ?? {};

    String message;

    if (statusCode == 201) {
      message = body['message'] ??
          'Registrasi berhasil. Menunggu persetujuan admin.';
      setState(() {
        _isLoading = false;
        _message = message;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    } else if (statusCode == 422 && body['errors'] != null) {
      final errors = body['errors'] as Map<String, dynamic>;
      final firstKey = errors.keys.first;
      final firstErrorList = errors[firstKey];
      if (firstErrorList is List && firstErrorList.isNotEmpty) {
        message = firstErrorList.first.toString();
      } else {
        message = body['message'] ?? 'Data tidak valid (422).';
      }
    } else if (statusCode == 0) {
      message = body['message'] ?? 'Gagal terhubung ke server.';
    } else {
      message = body['message'] ?? 'Registrasi gagal (kode $statusCode).';
    }

    setState(() {
      _isLoading = false;
      _message = message;
    });
  }

  // =========================
  // DATE PICKER TANGGAL LAHIR
  // =========================
  Future<void> _pickBirthDate() async {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // default initial date: 20 tahun yang lalu
    DateTime initial = DateTime(now.year - 20, now.month, now.day);

    if (_birthDateController.text.isNotEmpty) {
      final parsed = DateTime.tryParse(_birthDateController.text);
      if (parsed != null) {
        initial = parsed;
      }
    }

    final firstDate = DateTime(1950);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDate) ? lastDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (ctx, child) {
        final baseTheme = Theme.of(ctx);
        final colorScheme = baseTheme.colorScheme.copyWith(
          primary: _primaryBlue,
          onPrimary: Colors.white,
          secondary: _primaryBlue,
        );

        return Theme(
          data: baseTheme.copyWith(
            colorScheme: colorScheme,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryBlue, // warna tombol OK / Batal
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _birthDateController.text = '$y-$m-$d'; // YYYY-MM-DD
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color titleColor = isDark ? Colors.white : _darkBlue;
    final Color subtitleColor =
        isDark ? Colors.white70 : Colors.grey.shade700;

    final Color cardColor = isDark ? theme.cardColor : Colors.white;

    final Color cardBorderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.7);

    // Background: dark = solid, light = gradient (sama seperti Login)
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: backgroundDecoration,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bar atas: back + judul
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: titleColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Registrasi Kasir',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Deskripsi singkat
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Daftarkan diri Anda sebagai kasir. Admin akan meninjau dan menyetujui akun Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF57A0D3),
                                Color(0xFF3C82B2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: isDark
                                ? theme.colorScheme.surfaceVariant
                                : const Color(0xFFE7F0FF),
                            backgroundImage: _pickedImage != null
                                ? FileImage(File(_pickedImage!.path))
                                : null,
                            child: _pickedImage == null
                                ? Icon(
                                    Icons.person_outline,
                                    size: 48,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF90A4CE),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: InkWell(
                            onTap: _showPickImageSheet,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF57A0D3),
                                      Color(0xFF3C82B2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (_message != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _message!.toLowerCase().contains('berhasil')
                            ? const Color(0xFFE8F8EF)
                            : const Color(0xFFFFE8E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _message!.toLowerCase().contains('berhasil')
                                  ? const Color(0xFF46A36A)
                                  : const Color(0xFFD64545),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _message!.toLowerCase().contains('berhasil')
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            size: 18,
                            color:
                                _message!.toLowerCase().contains('berhasil')
                                    ? const Color(0xFF46A36A)
                                    : const Color(0xFFD64545),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    _message!.toLowerCase().contains('berhasil')
                                        ? const Color(0xFF2F7A4E)
                                        : const Color(0xFFB93636),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // CARD FORM
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 22,
                          spreadRadius: 2,
                          color: isDark
                              ? Colors.black.withOpacity(0.6)
                              : Colors.black.withOpacity(0.08),
                          offset: const Offset(0, 14),
                        ),
                      ],
                      border: Border.all(
                        color: cardBorderColor,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Data diri kasir',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nama
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration(
                              context: context,
                              label: 'Nama lengkap',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Nama wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              context: context,
                              label: 'Email',
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Email wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          // Phone
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              context: context,
                              label: 'No. telepon',
                              icon: Icons.phone_iphone,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'No. telepon wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          // Tanggal lahir (PAKAI DATE PICKER)
                          TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            decoration: _inputDecoration(
                              context: context,
                              label: 'Tanggal lahir (YYYY-MM-DD)',
                              icon: Icons.cake_outlined,
                            ).copyWith(
                              suffixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: _primaryBlue,
                              ),
                            ),
                            onTap: _pickBirthDate,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Tanggal lahir wajib diisi';
                              }
                              final regex =
                                  RegExp(r'^\d{4}-\d{2}-\d{2}$');
                              if (!regex.hasMatch(v)) {
                                return 'Format harus YYYY-MM-DD, contoh 2000-10-01';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              context: context,
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
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.length < 6
                                    ? 'Password minimal 6 karakter'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          // Konfirmasi Password
                          TextFormField(
                            controller: _passwordConfirmController,
                            obscureText: _obscureConfirmPassword,
                            decoration: _inputDecoration(
                              context: context,
                              label: 'Konfirmasi password',
                              icon: Icons.lock_person_outlined,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20,
                                  color: subtitleColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (v) =>
                                v != _passwordController.text
                                    ? 'Konfirmasi password tidak sama'
                                    : null,
                          ),

                          const SizedBox(height: 20),

                          // Tombol daftar
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton(
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
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
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Daftar Sekarang',
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
