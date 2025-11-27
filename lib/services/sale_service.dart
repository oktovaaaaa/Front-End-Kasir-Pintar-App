import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sale.dart';

class SaleService {
  // SESUAIKAN kalau baseUrl-mu beda
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Ambil list riwayat transaksi
  Future<List<Sale>> getSales() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/sales'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => Sale.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat riwayat (${response.statusCode})');
    }
  }

  /// Detail satu transaksi (untuk kasbon detail, riwayat detail)
  Future<Sale> getSaleDetail(int id) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/sales/$id'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Sale.fromJson(data);
    } else {
      throw Exception(
        'Gagal memuat detail transaksi (${response.statusCode})',
      );
    }
  }

  /// Untuk menyimpan transaksi baru (checkout)
  Future<Map<String, dynamic>> createSale({
    required Map<int, int> cart,
    required double paidAmount,
    String? customerName,
    int? customerId,
    String? paymentMethod,
  }) async {
    final token = await _getToken();

    final items = cart.entries
        .map((e) => {
              'product_id': e.key,
              'qty': e.value,
            })
        .toList();

    final body = <String, dynamic>{
      'items': items,
      'paid_amount': paidAmount,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null && customerName.trim().isNotEmpty)
        'customer_name': customerName.trim(),
      if (paymentMethod != null && paymentMethod.isNotEmpty)
        'payment_method': paymentMethod,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/sales'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'Gagal menyimpan transaksi');
    }
  }

  /// Melunasi / mencicil kasbon
  /// POST /sales/{id}/pay-kasbon  body: { "amount": 50000 }
 Future<Map<String, dynamic>> payKasbon({
  required int saleId,
  required double amount,
}) async {
  final token = await _getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/sales/$saleId/pay-kasbon'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'amount': amount}),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data as Map<String, dynamic>;
  } else {
    throw Exception(
      data['message'] ?? 'Gagal menyimpan pembayaran kasbon',
    );
  }
}

}
