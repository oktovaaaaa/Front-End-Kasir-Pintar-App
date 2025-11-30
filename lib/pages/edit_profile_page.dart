import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();

  bool _isLoading = false;
  String? _message;

  static const Color _primaryBlue = Color(0xFF57A0D3);
  static const Color _darkBlue = Color(0xFF1F2C46);

  // ==== STATE FOTO PROFIL (SEKARANG DI EDIT PROFILE) ====
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage; // foto baru yang dipilih dari galeri/kamera
  String? _currentPhotoUrl; // url/path foto dari server

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // ======== SESUAIKAN DENGAN AuthService KAMU =========
      final result = await _authService.getProfile();
      final statusCode = result['statusCode'] ?? 0;
      final body = result['body'] as Map<String, dynamic>? ?? {};

      if (statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>? ?? body;

        _nameController.text = data['name']?.toString() ?? '';
        _emailController.text = data['email']?.toString() ?? '';
        _phoneController.text = data['phone']?.toString() ?? '';
        _birthDateController.text = data['birth_date']?.toString() ?? '';

        // ambil field foto dari API (sesuaikan nama key kalau beda)
        _currentPhotoUrl = data['profile_photo']?.toString();
      } else {
        _message =
            body['message'] ?? 'Gagal memuat data profil (kode $statusCode).';
      }
    } catch (e) {
      _message = 'Terjadi kesalahan saat memuat profil.';
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // ======== SESUAIKAN PARAMETER & RESPONSE DENGAN API KAMU =========
      final result = await _authService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        birthDate: _birthDateController.text.trim(),
      );

      final statusCode = result['statusCode'] ?? 0;
      final body = result['body'] as Map<String, dynamic>? ?? {};

      if (statusCode == 200) {
        setState(() {
          _message = body['message'] ?? 'Profil berhasil diperbarui.';
        });
      } else {
        setState(() {
          _message =
              body['message'] ?? 'Gagal menyimpan profil (kode $statusCode).';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Terjadi kesalahan saat menyimpan profil.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
    );

    if (picked != null) {
      // boleh kamu format kalau mau: yyyy-MM-dd
      _birthDateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
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
      fillColor:
          isDark ? theme.colorScheme.surface : const Color(0xFFF5F8FE),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  // ======================
  // FOTO PROFIL HANDLER
  // ======================

  void _openPhotoOptions() {
    FocusScope.of(context).unfocus();
    final bool hasPhoto =
        _pickedImage != null ||
        (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(isDark ? 0.6 : 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Foto Profil',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: _primaryBlue,
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: theme.textTheme.bodyMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: _primaryBlue,
                ),
                title: Text(
                  'Ambil Foto',
                  style: theme.textTheme.bodyMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Hapus Foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePhoto();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
      await _uploadNewPhoto();
    }
  }

  Future<void> _uploadNewPhoto() async {
    if (_pickedImage == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _authService.updateProfilePhoto(
      filePath: _pickedImage!.path,
    );

    final statusCode = result['statusCode'] ?? 0;
    final body = result['body'] as Map<String, dynamic>? ?? {};

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (statusCode == 200) {
        _message = body['message'] ?? 'Foto profil berhasil diperbarui.';

        // kalau API mengembalikan path/url baru, ambil di sini
        final data = body['data'] as Map<String, dynamic>? ?? {};
        _currentPhotoUrl =
            data['profile_photo']?.toString() ?? _currentPhotoUrl;
      } else {
        _message = body['message'] ??
            'Gagal memperbarui foto profil (kode $statusCode).';
      }
    });
  }

  void _confirmDeletePhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto Profil'),
        content: const Text(
            'Kamu yakin mau menghapus foto profil? Foto akan diganti dengan avatar default.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePhoto();
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _authService.deleteProfilePhoto();
    final statusCode = result['statusCode'] ?? 0;
    final body = result['body'] as Map<String, dynamic>? ?? {};

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (statusCode == 200) {
        _message = body['message'] ?? 'Foto profil berhasil dihapus.';
        _pickedImage = null;
        _currentPhotoUrl = null;
      } else {
        _message = body['message'] ??
            'Gagal menghapus foto profil (kode $statusCode).';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final bool hasPhoto =
        _pickedImage != null ||
        (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty);

    // gradient background ikut mode
    final List<Color> bgGradientColors = isDark
        ? [
            theme.scaffoldBackgroundColor,
            theme.colorScheme.surface,
          ]
        : const [
            Color(0xFFe8f4fb),
            Color(0xFFc3ddf3),
          ];

    // warna teks header
    final Color headerTitleColor = isDark ? onSurface : _darkBlue;
    final Color headerSubtitleColor =
        isDark ? onSurface.withOpacity(0.7) : Colors.grey.shade700;

    // card color ikut theme
    final Color cardColor = theme.cardColor;

    return Scaffold(
      // background gradient biru (sama kayak login tapi adaptif)
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header + "avatar"
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _openPhotoOptions,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? cardColor : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.35 : 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: isDark
                                    ? theme.colorScheme.surfaceVariant
                                    : const Color(0xFFE5F0FF),
                                backgroundImage: _pickedImage != null
                                    ? FileImage(File(_pickedImage!.path))
                                    : (_currentPhotoUrl != null &&
                                            _currentPhotoUrl!.isNotEmpty
                                        ? NetworkImage(_currentPhotoUrl!)
                                            as ImageProvider
                                        : null),
                                child: (!hasPhoto)
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 45,
                                        color: _primaryBlue,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? cardColor
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    hasPhoto
                                        ? Icons.edit_rounded
                                        : Icons.add_a_photo_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Data Diri Kasir',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: headerTitleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Perbarui informasi profil kamu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: headerSubtitleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                                color: _message!
                                        .toLowerCase()
                                        .contains('berhasil')
                                    ? const Color(0xFF2F7A4E)
                                    : const Color(0xFFB93636),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Card form data diri
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 22,
                          spreadRadius: 2,
                          color: Colors.black
                              .withOpacity(isDark ? 0.4 : 0.08),
                          offset: const Offset(0, 14),
                        ),
                      ],
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white.withOpacity(0.7),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Informasi pribadi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: headerTitleColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Pastikan data sesuai dengan yang terdaftar di admin.',
                              style: TextStyle(
                                fontSize: 11,
                                color: headerSubtitleColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Nama
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration(
                              label: 'Nama lengkap',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Nama wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              label: 'Email kasir',
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Email wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Nomor HP
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              label: 'Nomor HP',
                              icon: Icons.phone_android_outlined,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Nomor HP wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Tanggal lahir
                          TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            onTap: _pickBirthDate,
                            decoration: _inputDecoration(
                              label: 'Tanggal lahir',
                              icon: Icons.cake_outlined,
                            ).copyWith(
                              suffixIcon: Icon(
                                Icons.calendar_month_outlined,
                                size: 18,
                                color: headerSubtitleColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tombol simpan
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _saveProfile,
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
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Simpan Perubahan',
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

                  const SizedBox(height: 12),

                  // Tombol kembali
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _primaryBlue,
                      ),
                    ),
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
