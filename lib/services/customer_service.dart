import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';

class CustomerService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // sesuaikan

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Customer>> getCustomers() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/customers'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => Customer.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat pelanggan (${response.statusCode})');
    }
  }

  Future<Customer> getCustomerDetail(int id) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/customers/$id'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Customer.fromJson(data);
    } else {
      throw Exception('Gagal memuat detail pelanggan (${response.statusCode})');
    }
  }

  Future<Customer> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? company,
    String? note,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'company': company,
        'note': note,
      }),
    );

    if (response.statusCode == 201) {
      return Customer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal menambah pelanggan (${response.statusCode})');
    }
  }

  Future<Customer> updateCustomer({
    required int id,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? company,
    String? note,
  }) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/customers/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'company': company,
        'note': note,
      }),
    );

    if (response.statusCode == 200) {
      return Customer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal mengupdate pelanggan (${response.statusCode})');
    }
  }

  Future<void> deleteCustomer(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/customers/$id'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus pelanggan (${response.statusCode})');
    }
  }
}
