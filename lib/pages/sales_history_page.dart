import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sale.dart';
import '../services/sale_service.dart';

class SalesHistoryPage extends StatefulWidget {
  final VoidCallback onUserActivity;

  const SalesHistoryPage({super.key, required this.onUserActivity});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  final SaleService _saleService = SaleService();
  final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

  bool _isLoading = false;
  List<Sale> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final data = await _saleService.getSales();
      setState(() {
        _sales = data;
      });
    } catch (e) {
      _showSnack('Gagal memuat riwayat: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDetail(Sale sale) {
    widget.onUserActivity();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Detail Transaksi #${sale.id}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _dateFormatter.format(sale.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // LIST ITEM
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: sale.items.length,
                  itemBuilder: (context, index) {
                    final item = sale.items[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.productName),
                      subtitle: Text(
                        '${item.qty}x  ${_priceFormatter.format(item.price)}',
                      ),
                      trailing: Text(
                        _priceFormatter.format(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total'),
                  Text(
                    _priceFormatter.format(sale.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dibayar'),
                  Text(_priceFormatter.format(sale.paidAmount)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian'),
                  Text(_priceFormatter.format(sale.changeAmount)),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Status: ${sale.status == 'paid' ? 'Lunas' : 'Kasbon'}',
                  style: TextStyle(
                    color: sale.status == 'paid'
                        ? Colors.green
                        : Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (sale.customerName != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pelanggan: ${sale.customerName}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sales.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadSales,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('Belum ada riwayat transaksi')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSales,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _sales.length,
        itemBuilder: (context, index) {
          final sale = _sales[index];
          final isKasbon = sale.status == 'kasbon';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => _openDetail(sale),
              leading: CircleAvatar(
                backgroundColor: isKasbon
                    ? Colors.orange[100]
                    : Colors.green[100],
                child: Icon(
                  isKasbon ? Icons.receipt_long : Icons.check_circle,
                  color: isKasbon ? Colors.orange[800] : Colors.green,
                ),
              ),
              title: Text(
                _priceFormatter.format(sale.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateFormatter.format(sale.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (sale.customerName != null)
                    Text(
                      sale.customerName!,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isKasbon ? Colors.orange[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isKasbon ? 'Kasbon' : 'Lunas',
                      style: TextStyle(
                        fontSize: 11,
                        color: isKasbon ? Colors.orange[800] : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
