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

  // ==== FOTO PROFIL (OPSIONAL) ====
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage; // kalau null, tampilkan icon user

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
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Hapus foto (kosongkan)'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _pickedImage = null;
                  });
                },
              ),
            ],
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
      // kalau nanti API-nya sudah siap, bisa kirim path / file:
      // profileImagePath: _pickedImage?.path,
    );

    final statusCode = result['statusCode'] ?? 0;
    final body = result['body'] as Map<String, dynamic>? ?? {};

    String message;

    if (statusCode == 201) {
      message =
          body['message'] ?? 'Registrasi berhasil. Menunggu persetujuan admin.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Registrasi Kasir'),
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        foregroundColor: const Color(0xFF1F2C46),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register Now',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2C46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Daftarkan diri Anda sebagai kasir. Admin akan meninjau dan menyetujui akun Anda.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // ===== AVATAR SEPERTI DESAIN, OPSIONAL =====
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFE0E6FF),
                        backgroundImage: _pickedImage != null
                            ? FileImage(File(_pickedImage!.path))
                            : null,
                        child: _pickedImage == null
                            ? const Icon(
                                Icons.person_outline,
                                size: 48,
                                color: Color(0xFF9FA8DA),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _showPickImageSheet,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF5C6BC0),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.toLowerCase().contains('berhasil')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withOpacity(0.06),
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Email wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'No. Telepon',
                            prefixIcon: const Icon(Icons.phone_iphone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'No. telepon wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _birthDateController,
                          decoration: InputDecoration(
                            labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                            prefixIcon: const Icon(Icons.cake_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Tanggal lahir wajib diisi';
                            }
                            final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                            if (!regex.hasMatch(v)) {
                              return 'Format harus YYYY-MM-DD, contoh 2000-10-01';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Password minimal 6 karakter'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordConfirmController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (v) =>
                              v != _passwordController.text
                                  ? 'Konfirmasi password tidak sama'
                                  : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1F2C46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Daftar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
