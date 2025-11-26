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

  final DateFormat _dateFormatter =
      DateFormat('dd MMM yyyy • HH:mm', 'id_ID');

  static const Color _primaryBlue = Color(0xFF57A0D3);

  bool _isLoading = false;
  List<Sale> _sales = [];

  // FILTER TAB (Semua / Lunas / Utang)
  int _tabIndex = 0; // 0 = semua, 1 = lunas, 2 = utang

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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ======== UI HELPERS =========

  List<Sale> get _filteredSales {
    if (_tabIndex == 1) {
      // lunas
      return _sales.where((s) => s.status == 'paid').toList();
    } else if (_tabIndex == 2) {
      // utang (kasbon)
      return _sales.where((s) => s.status == 'kasbon').toList();
    }
    return _sales;
  }

  Color _statusColorBg(Sale sale) {
    final isUtang = sale.status == 'kasbon';
    return isUtang ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9);
  }

  Color _statusColorText(Sale sale) {
    final isUtang = sale.status == 'kasbon';
    return isUtang ? const Color(0xFFF57C00) : const Color(0xFF2E7D32);
  }

  String _statusLabel(Sale sale) {
    return sale.status == 'kasbon' ? 'Utang' : 'Lunas';
  }

  double _sisaUtang(Sale sale) {
    if (sale.status != 'kasbon') return 0;
    final sisa = sale.totalAmount - sale.paidAmount;
    return sisa < 0 ? 0 : sisa;
  }

  int _totalItemQty(Sale sale) {
    return sale.items.fold<int>(0, (prev, item) => prev + item.qty);
  }

  // ======== DETAIL BOTTOM SHEET =========

  void _openDetail(Sale sale) {
    widget.onUserActivity();

    final totalQty = _totalItemQty(sale);
    final sisaUtang = _sisaUtang(sale);
    final isUtang = sale.status == 'kasbon';

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
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Transaksi #${sale.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColorBg(sale),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(sale),
                      style: TextStyle(
                        color: _statusColorText(sale),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _dateFormatter.format(sale.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (sale.customerName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Pelanggan: ${sale.customerName}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),

              // RINGKASAN JUMLAH ITEM
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total barang dibeli',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      '$totalQty pcs',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // LIST ITEM
              SizedBox(
                height: 260,
                child: ListView.separated(
                  itemCount: sale.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final item = sale.items[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // bullet / indikator kecil
                        Container(
                          width: 4,
                          height: 40,
                          margin: const EdgeInsets.only(right: 10, top: 4),
                          decoration: BoxDecoration(
                            color: _primaryBlue.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.qty}x  ${_priceFormatter.format(item.price)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total: ${_priceFormatter.format(item.subtotal)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 24),

              // TOTAL & PEMBAYARAN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Belanja',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    _priceFormatter.format(sale.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dibayar'),
                  Text(
                    _priceFormatter.format(sale.paidAmount),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian'),
                  Text(
                    _priceFormatter.format(sale.changeAmount),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              if (isUtang) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sisa utang yang harus dibayar',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      _priceFormatter.format(sisaUtang),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD84315),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sisa ini akan tercatat sebagai utang pelanggan.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ============= BUILD =============

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

    final list = _filteredSales;

    return RefreshIndicator(
      onRefresh: _loadSales,
      child: Column(
        children: [
          const SizedBox(height: 8),

          // TAB FILTER (All / Lunas / Utang) mirip desain gambar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTabChip(0, 'Semua'),
                  _buildTabChip(1, 'Lunas'),
                  _buildTabChip(2, 'Utang'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final sale = list[index];
                final isUtang = sale.status == 'kasbon';
                final sisaUtang = _sisaUtang(sale);

                return GestureDetector(
                  onTap: () => _openDetail(sale),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // strip warna di kiri
                        Container(
                          width: 6,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isUtang
                                ? const Color(0xFFFFA726)
                                : _primaryBlue,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // baris atas: nominal & chip status
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _priceFormatter
                                          .format(sale.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColorBg(sale),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _statusLabel(sale),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _statusColorText(sale),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // tanggal
                                Text(
                                  _dateFormatter.format(sale.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                // nama pelanggan atau placeholder
                                Text(
                                  sale.customerName ?? 'Pelanggan umum',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isUtang && sisaUtang > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Sisa utang: ${_priceFormatter.format(sisaUtang)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFD84315),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(int index, String label) {
    final isActive = _tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? _primaryBlue : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
