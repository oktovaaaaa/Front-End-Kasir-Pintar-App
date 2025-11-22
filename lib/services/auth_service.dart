import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  final String _baseUrl = AppConfig.baseUrl;

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

      final response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
            },
            body: {
              'name': name,
              'email': email,
              'phone': phone,
              'birth_date': birthDate, // pastikan format: YYYY-MM-DD
              'password': password,
              'password_confirmation': passwordConfirmation,
            },
          )
          .timeout(const Duration(seconds: 15));

      // coba decode JSON; kalau server balikin HTML error, jangan bikin app crash
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
      // misal koneksi gagal, timeout, dsb.
      return {
        'statusCode': 0,
        'body': {
          'message': 'Gagal terhubung ke server: $e',
        },
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/login');

      final response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
            },
            body: {
              'email': email,
              'password': password,
            },
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = {
          'message':
              'Server mengirim respon non-JSON (status ${response.statusCode}).'
        };
      }

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('saved_email', email); // untuk isi otomatis nanti
      }

      return {
        'statusCode': response.statusCode,
        'body': data,
      };
    } catch (e) {
      return {
        'statusCode': 0,
        'body': {
          'message': 'Gagal terhubung ke server: $e',
        },
      };
    }
  }

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
      } catch (_) {
        // kalau logout ke server gagal, tetap hapus token lokal
      }
    }

    // hanya hapus token, biar email masih tersimpan
    await prefs.remove('token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_email');
  }
}
