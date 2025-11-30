import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  final String _baseUrl = AppConfig.baseUrl;

  // =====================================================
  // REGISTER
  // =====================================================
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String birthDate,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/register');
      print('REGISTER URL: $uri');

      final response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phone,
              'birth_date': birthDate, // contoh: 2000-10-01
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('REGISTER STATUS: ${response.statusCode}');
      print('REGISTER BODY: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = {
          'message':
              'Server mengirim respon non-JSON (status ${response.statusCode}).'
        };
      }

      return {
        'statusCode': response.statusCode,
        'body': data,
      };
    } catch (e) {
      print('REGISTER ERROR: $e');
      return {
        'statusCode': 0,
        'body': {
          'message': 'Gagal terhubung ke server: $e',
        },
      };
    }
  }

  // =====================================================
  // LOGIN
  // =====================================================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/login');
      print('LOGIN URL: $uri');

      final response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('LOGIN STATUS: ${response.statusCode}');
      print('LOGIN BODY: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = {
          'message':
              'Server mengirim respon non-JSON (status ${response.statusCode}).'
        };
      }

      // simpan token & email untuk auto-login / remember email
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }
        await prefs.setString('saved_email', email);
      }

      return {
        'statusCode': response.statusCode,
        'body': data,
      };
    } catch (e) {
      print('LOGIN ERROR: $e');
      return {
        'statusCode': 0,
        'body': {
          'message': 'Gagal terhubung ke server: $e',
        },
      };
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        final uri = Uri.parse('$_baseUrl/api/auth/logout');
        await http.post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        print('LOGOUT ERROR: $e');
      }
    }

    await prefs.remove('token');
  }

  // =====================================================
  // TOKEN & EMAIL TERSIMPAN
  // =====================================================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_email');
  }

  // =====================================================
  // PROFIL KASIR: GET
  // =====================================================
  ///
  /// GET /api/auth/me
  /// Sesuaikan dengan route Laravel kamu kalau beda.
  ///
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$_baseUrl/api/auth/me');
      print('GET PROFILE URL: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('GET PROFILE STATUS: ${response.statusCode}');
      print('GET PROFILE BODY: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = {
          'message':
              'Server mengirim respon non-JSON (status ${response.statusCode}).'
        };
      }

      return {
        'statusCode': response.statusCode,
        'body': data,
      };
    } catch (e) {
      print('GET PROFILE ERROR: $e');
      return {
        'statusCode': 0,
        'body': {
          'message': 'Gagal terhubung ke server: $e',
        },
      };
    }
  }

  // =====================================================
  // PROFIL KASIR: UPDATE
  // =====================================================
  ///
  /// PUT /api/auth/me
  /// Body: { name, email, phone, birth_date }
  ///
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String birthDate,
  }) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$_baseUrl/api/auth/me');
      print('UPDATE PROFILE URL: $uri');

      final response = await http
          .put(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phone,
              'birth_date': birthDate,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('UPDATE PROFILE STATUS: ${response.statusCode}');
      print('UPDATE PROFILE BODY: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = {
          'message':
              'Server mengirim respon non-JSON (status ${response.statusCode}).'
        };
      }

      return {
        'statusCode': response.statusCode,
        'body': data,
      };
    } catch (e) {
      print('UPDATE PROFILE ERROR: $e');
      return {
        'statusCode': 0,
        'body': {
          'message': 'Gagal terhubung ke server: $e',
        },
      };
    }
  }

  // =====================================================
  // UPDATE FOTO PROFIL
  // =====================================================
  ///
  /// CONTOH: POST /api/auth/profile/photo
  /// Sesuaikan URL & nama field file dengan Laravel kamu.
  ///
  Future<Map<String, dynamic>> updateProfilePhoto({
    required String filePath,
  }) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$_baseUrl/api/auth/profile/photo');
      print('UPDATE PROFILE PHOTO URL: $uri');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      // ganti 'photo' kalau di backend field-nya beda, misal 'profile_photo'
      request.files.add(
        await http.MultipartFile.fromPath('photo', filePath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('UPDATE PROFILE PHOTO STATUS: ${response.statusCode}');
      print('UPDATE PROFILE PHOTO BODY: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = {
          'message':
              'Server mengirim respon non-JSON (status ${response.statusCode}).'
        };
      }

      return {
        'statusCode': response.statusCode,
        'body': data,
      };
    } catch (e) {
      print('UPDATE PROFILE PHOTO ERROR: $e');
      return {
        'statusCode': 0,
        'body': {
          'message': 'Gagal terhubung ke server: $e',
        },
      };
    }
  }

  // =====================================================
  // HAPUS FOTO PROFIL
  // =====================================================
  ///
  /// CONTOH: DELETE /api/auth/profile/photo
  /// Sesuaikan URL dengan Laravel kamu.
  ///
  Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$_baseUrl/api/auth/profile/photo');
      print('DELETE PROFILE PHOTO URL: $uri');

      final response = await http
          .delete(
            uri,
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('DELETE PROFILE PHOTO STATUS: ${response.statusCode}');
      print('DELETE PROFILE PHOTO BODY: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = {
          'message':
              'Server mengirim respon non-JSON (status ${response.statusCode}).'
        };
      }

      return {
        'statusCode': response.statusCode,
        'body': data,
      };
    } catch (e) {
      print('DELETE PROFILE PHOTO ERROR: $e');
      return {
        'statusCode': 0,
        'body': {
          'message': 'Gagal terhubung ke server: $e',
        },
      };
    }
  }
}
