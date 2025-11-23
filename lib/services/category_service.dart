import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';

class CategoryService {
  // GANTI baseUrl ini sesuai IP backend kamu
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Category>> getCategories() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat kategori (${response.statusCode})');
    }
  }

  Future<Category> createCategory({
    required String name,
    String? description,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal menambah kategori (${response.statusCode})');
    }
  }
}
