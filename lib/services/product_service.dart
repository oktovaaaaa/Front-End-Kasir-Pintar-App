import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class ProductService {
  // SESUAIKAN kalau base URL kamu beda
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // GET /api/products
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

  // POST /api/products
  Future<Product> createProduct({
    required String name,
    required int price,        // harga jual
    required int costPrice,    // harga modal
    required int stock,
    int? categoryId,
    String? description,
    File? imageFile,
  }) async {
    final token = await _getToken();

    final uri = Uri.parse('$baseUrl/products');
    final request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['price'] = price.toString();
    request.fields['cost_price'] = costPrice.toString();
    request.fields['stock'] = stock.toString();
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

    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Gagal menambah produk (${response.statusCode})');
    }
  }

  // PUT /api/products/{id}
  Future<Product> updateProduct({
    required int id,
    required String name,
    required int price,
    required int costPrice,
    required int stock,
    int? categoryId,
    String? description,
    File? imageFile,
  }) async {
    final token = await _getToken();

    final uri = Uri.parse('$baseUrl/products/$id');
    final request = http.MultipartRequest('POST', uri);
    request.fields['_method'] = 'PUT';

    request.fields['name'] = name;
    request.fields['price'] = price.toString();
    request.fields['cost_price'] = costPrice.toString();
    request.fields['stock'] = stock.toString();
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

    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Gagal mengupdate produk (${response.statusCode})');
    }
  }

  // DELETE /api/products/{id}
  Future<void> deleteProduct(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Gagal menghapus produk');
      } catch (_) {
        throw Exception('Gagal menghapus produk (${response.statusCode})');
      }
    }
  }
}
