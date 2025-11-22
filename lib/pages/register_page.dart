import 'package:flutter/material.dart';
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _authService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      birthDate: _birthDateController.text.trim(), // format YYYY-MM-DD
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmController.text,
    );

    setState(() {
      _isLoading = false;
      _message = result['body']['message'] ??
          (result['statusCode'] == 201
              ? 'Registrasi berhasil, tunggu approve admin'
              : 'Registrasi gagal');
    });

    if (result['statusCode'] == 201) {
      // setelah register, kembali ke halaman login
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Kasir')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _message!.toLowerCase().contains('berhasil')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v == null || v.isEmpty ? 'Email wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'No. Telepon'),
                    validator: (v) => v == null || v.isEmpty ? 'No. telepon wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: _birthDateController,
                    decoration:
                        const InputDecoration(labelText: 'Tanggal Lahir (YYYY-MM-DD)'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Tanggal lahir wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Minimal 6 karakter' : null,
                  ),
                  TextFormField(
                    controller: _passwordConfirmController,
                    decoration:
                        const InputDecoration(labelText: 'Konfirmasi Password'),
                    obscureText: true,
                    validator: (v) =>
                        v != _passwordController.text ? 'Konfirmasi tidak sama' : null,
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _register,
                          child: const Text('Daftar'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
