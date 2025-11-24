import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Laporan keuntungan overall per periode (harian/mingguan/bulanan/tahunan)
  /// GET /reports/profit?period=daily|weekly|monthly|yearly
  Future<List<Map<String, dynamic>>> getProfitSummary(String period) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/reports/profit?period=$period'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Gagal memuat laporan keuntungan (${response.statusCode})');
    }
  }

  /// Keuntungan per produk PER PERIODE
  /// GET /reports/profit-by-product?period=daily|weekly|monthly|yearly
  Future<List<Map<String, dynamic>>> getProfitByProduct(String period) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/reports/profit-by-product?period=$period'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Gagal memuat keuntungan per produk (${response.statusCode})');
    }
  }

  /// Keuntungan per kategori PER PERIODE
  /// GET /reports/profit-by-category?period=daily|weekly|monthly|yearly
  Future<List<Map<String, dynamic>>> getProfitByCategory(String period) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/reports/profit-by-category?period=$period'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Gagal memuat keuntungan per kategori (${response.statusCode})');
    }
  }

  /// Daftar kasbon (belum lunas)
  Future<List<Map<String, dynamic>>> getKasbonList() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/reports/kasbon'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Gagal memuat data kasbon (${response.statusCode})');
    }
  }
}
