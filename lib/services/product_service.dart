import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class ProductService {
  // GANTI baseUrl sesuai IP backend kamu
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Product>> getProducts() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat produk (${response.statusCode})');
    }
  }

  Future<Product> createProduct({
    required String name,
    required int stock,
    required double price,
    int? categoryId,
    String? description,
    File? imageFile,
  }) async {
    final token = await _getToken();

    final uri = Uri.parse('$baseUrl/products');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json';

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['name'] = name;
    request.fields['stock'] = stock.toString();
    request.fields['price'] = price.toString();
    if (categoryId != null) {
      request.fields['category_id'] = categoryId.toString();
    }
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal menambah produk (${response.statusCode})');
    }
  }

  Future<Product> updateProduct({
    required int id,
    required String name,
    required int stock,
    required double price,
    int? categoryId,
    String? description,
    File? imageFile,
  }) async {
    final token = await _getToken();

    final uri = Uri.parse('$baseUrl/products/$id');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..fields['_method'] = 'PUT'; // spoofing method PUT

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['name'] = name;
    request.fields['stock'] = stock.toString();
    request.fields['price'] = price.toString();
    if (categoryId != null) {
      request.fields['category_id'] = categoryId.toString();
    }
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal mengupdate produk (${response.statusCode})');
    }
  }

  Future<void> deleteProduct(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus produk (${response.statusCode})');
    }
  }
}
