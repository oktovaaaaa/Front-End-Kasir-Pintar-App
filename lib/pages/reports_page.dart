import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/report_service.dart';
import '../services/sale_service.dart';
import '../models/sale.dart';

class ReportsPage extends StatefulWidget {
  final VoidCallback onUserActivity;

  const ReportsPage({super.key, required this.onUserActivity});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  final ReportService _reportService = ReportService();
  final SaleService _saleService = SaleService();

  final NumberFormat _money =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const Color _primaryBlue = Color(0xFF57A0D3);

  // state laporan
  String _period = 'daily'; // daily, weekly, monthly, yearly
  bool _loadingSummary = false;
  bool _loadingProd = false;
  bool _loadingCat = false;
  bool _loadingKasbon = false;

  List<Map<String, dynamic>> _summary = [];
  List<Map<String, dynamic>> _profitProducts = [];
  List<Map<String, dynamic>> _profitCategories = [];
  List<Map<String, dynamic>> _kasbon = [];

  // search
  String _productSearch = '';
  String _categorySearch = '';

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  Future<void> _loadAllReports() async {
    await Future.wait([
      _loadSummary(),
      _loadProductProfit(),
      _loadCategoryProfit(),
      _loadKasbon(),
    ]);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final data = await _reportService.getProfitSummary(_period);
      setState(() {
        _summary = data;
      });
    } catch (e) {
      _showSnack('Gagal memuat ringkasan: $e');
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _loadProductProfit() async {
    setState(() => _loadingProd = true);
    try {
      final data = await _reportService.getProfitByProduct(_period);
      setState(() {
        _profitProducts = data;
      });
    } catch (e) {
      _showSnack('Gagal memuat keuntungan produk: $e');
    } finally {
      if (mounted) setState(() => _loadingProd = false);
    }
  }

  Future<void> _loadCategoryProfit() async {
    setState(() => _loadingCat = true);
    try {
      final data = await _reportService.getProfitByCategory(_period);
      setState(() {
        _profitCategories = data;
      });
    } catch (e) {
      _showSnack('Gagal memuat keuntungan kategori: $e');
    } finally {
      if (mounted) setState(() => _loadingCat = false);
    }
  }

  Future<void> _loadKasbon() async {
    setState(() => _loadingKasbon = true);
    try {
      final data = await _reportService.getKasbonList();
      setState(() {
        _kasbon = data;
      });
    } catch (e) {
      _showSnack('Gagal memuat kasbon: $e');
    } finally {
      if (mounted) setState(() => _loadingKasbon = false);
    }
  }

  // ========= DETAIL KASBON (TAB KEDUA) =========

  Future<void> _openKasbonDetail(Map<String, dynamic> row) async {
    widget.onUserActivity();

    final int saleId = int.tryParse(row['id'].toString()) ?? 0;
    if (saleId == 0) return;

    try {
      final Sale sale = await _saleService.getSaleDetail(saleId);

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
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Detail Kasbon #${sale.id}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    sale.customerName != null
                        ? 'Pelanggan: ${sale.customerName}'
                        : 'Pelanggan tidak diketahui',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
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
                            '${item.qty}x  ${_money.format(item.price)}'),
                        trailing: Text(
                          _money.format(item.subtotal),
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
                      _money.format(sale.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dibayar'),
                    Text(_money.format(sale.paidAmount)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sisa'),
                    Text(
                      _money
                          .format(sale.totalAmount - sale.paidAmount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fitur pembayaran cicilan akan ditambahkan nanti.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showSnack('Gagal memuat detail kasbon: $e');
    }
  }

  // ========= DETAIL RINGKASAN (4 CARD ATAS) =========

  void _openOverviewDetail(String type) {
    widget.onUserActivity();

    final totalProfit = _summary.fold<double>(
      0,
      (prev, row) =>
          prev +
          (double.tryParse(row['total_profit'].toString()) ?? 0.0),
    );
    final totalSales = _summary.fold<double>(
      0,
      (prev, row) =>
          prev +
          (double.tryParse(row['total_sales'].toString()) ?? 0.0),
    );
    final totalTrx = _summary.fold<int>(
      0,
      (prev, row) =>
          prev +
          (int.tryParse(row['transaksi'].toString()) ?? 0),
    );
    final totalQty = _profitProducts.fold<int>(
      0,
      (prev, row) =>
          prev +
          (int.tryParse(row['total_qty'].toString()) ?? 0),
    );

    String title = '';
    Widget content = const SizedBox.shrink();

    switch (type) {
      case 'profit':
        title = 'Detail Total Profit';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _money.format(totalProfit),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Periode ini dihasilkan dari produk berikut:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ..._profitProducts.take(10).map((row) {
              final name = row['product_name']?.toString() ?? '';
              final profit = double.tryParse(
                      row['total_profit'].toString()) ??
                  0.0;
              final qty =
                  int.tryParse(row['total_qty'].toString()) ?? 0;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(name),
                subtitle: Text('Terjual $qty pcs'),
                trailing: Text(
                  _money.format(profit),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            }),
          ],
        );
        break;
      case 'sales':
        title = 'Detail Total Penjualan';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _money.format(totalSales),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Omzet terbesar berasal dari produk berikut:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ..._profitProducts.take(10).map((row) {
              final name = row['product_name']?.toString() ?? '';
              final sales = double.tryParse(
                      row['total_sales'].toString()) ??
                  0.0;
              final qty =
                  int.tryParse(row['total_qty'].toString()) ?? 0;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(name),
                subtitle: Text('Terjual $qty pcs'),
                trailing: Text(
                  _money.format(sales),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              );
            }),
          ],
        );
        break;
      case 'trx':
        title = 'Detail Transaksi';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$totalTrx transaksi',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ringkasan jumlah transaksi per periode:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: _summary.length,
                itemBuilder: (context, index) {
                  final row = _summary[index];
                  final label =
                      _formatPeriodLabel(row['period_label'].toString());
                  final trx =
                      int.tryParse(row['transaksi'].toString()) ?? 0;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    trailing: Text('$trx trx'),
                  );
                },
              ),
            ),
          ],
        );
        break;
      case 'qty':
        title = 'Detail Produk Terjual';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$totalQty pcs',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Produk dengan jumlah terjual terbanyak:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ..._profitProducts.take(20).map((row) {
              final name = row['product_name']?.toString() ?? '';
              final qty =
                  int.tryParse(row['total_qty'].toString()) ?? 0;
              final sales = double.tryParse(
                      row['total_sales'].toString()) ??
                  0.0;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(name),
                subtitle:
                    Text('Terjual $qty pcs • Omzet ${_money.format(sales)}'),
              );
            }),
          ],
        );
        break;
    }

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                content,
              ],
            ),
          ),
        );
      },
    );
  }

  // ========= DETAIL PRODUK & KATEGORI (LIST BAWAH) =========

  Future<void> _openProductDetail(Map<String, dynamic> row) async {
    widget.onUserActivity();

    final int productId =
        int.tryParse(row['product_id'].toString()) ?? 0;
    if (productId == 0) return;

    try {
      final sales = await _saleService.getSales();
      // kumpulkan transaksi yang mengandung produk ini
      final List<_ProductTxnRow> txns = [];

      for (final sale in sales) {
        for (final item in sale.items) {
          if (item.productId == productId) {
            txns.add(
              _ProductTxnRow(
                saleId: sale.id,
                date: sale.createdAt,
                customerName: sale.customerName ?? '-',
                qty: item.qty,
                subtotal: item.subtotal,
              ),
            );
          }
        }
      }

      txns.sort((a, b) => b.date.compareTo(a.date));

      final totalQty = txns.fold<int>(0, (p, t) => p + t.qty);
      final totalSales =
          txns.fold<double>(0, (p, t) => p + t.subtotal);

      final productName = row['product_name']?.toString() ?? '';

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
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terjual $totalQty pcs • Omzet ${_money.format(totalSales)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: txns.isEmpty
                      ? const Center(
                          child: Text(
                              'Belum ada transaksi detail untuk produk ini'),
                        )
                      : ListView.builder(
                          itemCount: txns.length,
                          itemBuilder: (context, index) {
                            final t = txns[index];
                            final dateStr = DateFormat(
                              'dd MMM yyyy • HH:mm',
                              'id_ID',
                            ).format(t.date);
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(dateStr),
                              subtitle: Text(
                                  'Pelanggan: ${t.customerName}\nQty: ${t.qty} pcs'),
                              isThreeLine: true,
                              trailing: Text(
                                _money.format(t.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showSnack('Gagal memuat detail produk: $e');
    }
  }

  Future<void> _openCategoryDetail(Map<String, dynamic> row) async {
    widget.onUserActivity();

    final int categoryId =
        int.tryParse(row['category_id'].toString()) ?? 0;
    if (categoryId == 0) return;

    try {
      final sales = await _saleService.getSales();
      final List<_ProductTxnRow> txns = [];

      for (final sale in sales) {
        for (final item in sale.items) {
          // di model SaleItem kita hanya punya productId & productName,
          // jadi detail kategori yang sangat presisi membutuhkan
          // penyesuaian backend / model.
          // Untuk sementara: kita tampilkan transaksi berdasarkan nama kategori
          // dari laporan ringkasan saja (tanpa filter transaksi per kategori).
        }
      }

      final categoryName = row['category_name']?.toString() ?? '';
      final totalQty =
          int.tryParse(row['total_qty'].toString()) ?? 0;
      final totalSales =
          double.tryParse(row['total_sales'].toString()) ?? 0.0;
      final profit =
          double.tryParse(row['total_profit'].toString()) ?? 0.0;

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Terjual $totalQty pcs • Omzet ${_money.format(totalSales)}\nProfit ${_money.format(profit)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Detail transaksi per kategori bisa dibuat lebih rinci '
                    'dengan penyesuaian backend (mengembalikan kategori '
                    'di setiap item transaksi). Untuk sekarang, data di atas '
                    'menggunakan ringkasan laporan.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      _showSnack('Gagal memuat detail kategori: $e');
    }
  }

  // ========= UI =========

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          _buildSegmentedTab(),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                _buildProfitTab(),
                _buildKasbonTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSegmentedTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const TabBar(
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(text: 'Laporan Keuntungan'),
          Tab(text: 'Kasbon'),
        ],
      ),
    );
  }

  // ---- TAB: LAPORAN KEUNTUNGAN ----

  Widget _buildProfitTab() {
    if (_loadingSummary && _summary.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalProfit = _summary.fold<double>(
      0,
      (prev, row) =>
          prev +
          (double.tryParse(row['total_profit'].toString()) ?? 0.0),
    );
    final totalSales = _summary.fold<double>(
      0,
      (prev, row) =>
          prev +
          (double.tryParse(row['total_sales'].toString()) ?? 0.0),
    );
    final totalTrx = _summary.fold<int>(
      0,
      (prev, row) =>
          prev +
          (int.tryParse(row['transaksi'].toString()) ?? 0),
    );
    final totalQty = _profitProducts.fold<int>(
      0,
      (prev, row) =>
          prev +
          (int.tryParse(row['total_qty'].toString()) ?? 0),
    );

    return RefreshIndicator(
      onRefresh: _loadAllReports,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 12),
          _buildSummaryGrid(
            totalProfit,
            totalSales,
            totalTrx,
            totalQty,
          ),
          const SizedBox(height: 16),
          _buildProfitChart(),
          const SizedBox(height: 16),
          _buildProductProfitSection(),
          const SizedBox(height: 16),
          _buildCategoryProfitSection(),
        ],
      ),
    );
  }

Widget _buildPeriodSelector() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _period,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: const [
            DropdownMenuItem(
              value: 'daily',
              child: Text("Harian"),
            ),
            DropdownMenuItem(
              value: 'weekly',
              child: Text("Mingguan"),
            ),
            DropdownMenuItem(
              value: 'monthly',
              child: Text("Bulanan"),
            ),
            DropdownMenuItem(
              value: 'yearly',
              child: Text("Tahunan"),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _period = value;
            });
            _loadSummary();
          },
        ),
      ),
    ),
  );
}



  Widget _periodChip(String value, String label) {
    final bool selected = _period == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (!val) return;
        setState(() {
          _period = value;
        });
        _loadSummary();
        _loadProductProfit();
        _loadCategoryProfit();
      },
    );
  }

  Widget _buildSummaryGrid(
      double totalProfit, double totalSales, int totalTrx, int totalQty) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _summaryCard(
          icon: Icons.trending_up,
          iconColor: Colors.green,
          title: 'Total Profit',
          value: _money.format(totalProfit),
          onTap: () => _openOverviewDetail('profit'),
        ),
        _summaryCard(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: _primaryBlue,
          title: 'Total Penjualan',
          value: _money.format(totalSales),
          onTap: () => _openOverviewDetail('sales'),
        ),
        _summaryCard(
          icon: Icons.receipt_long,
          iconColor: Colors.purple,
          title: 'Transaksi',
          value: '$totalTrx',
          onTap: () => _openOverviewDetail('trx'),
        ),
        _summaryCard(
          icon: Icons.shopping_bag_outlined,
          iconColor: Colors.orange,
          title: 'Produk Terjual',
          value: '$totalQty pcs',
          onTap: () => _openOverviewDetail('qty'),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.05),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// ==== GRAFIK KEUNTUNGAN ====

  // Format label periode sesuai pilihan (_period)
  String _formatPeriodLabel(String rawLabel) {
    try {
      final dt = DateTime.parse(rawLabel);

      switch (_period) {
        case 'daily':
          return DateFormat('dd/MM').format(dt); // 24/11
        case 'weekly':
          final endOfWeek = dt.add(const Duration(days: 6));
          final start = DateFormat('dd/MM').format(dt);
          final end = DateFormat('dd/MM').format(endOfWeek);
          return '$start\n$end';
        case 'monthly':
          return DateFormat('MMM yy', 'id_ID').format(dt); // Nov 25
        case 'yearly':
          return DateFormat('yyyy').format(dt); // 2025
        default:
          return DateFormat('dd/MM').format(dt);
      }
    } catch (_) {
      return rawLabel;
    }
  }

  Widget _buildProfitChart() {
    if (_summary.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const Text('Belum ada data untuk grafik'),
      );
    }

    final spots = <FlSpot>[];
    final Map<int, String> labels = {};

    for (int i = 0; i < _summary.length; i++) {
      final row = _summary[i];
      final profit =
          double.tryParse(row['total_profit'].toString()) ?? 0.0;
      final raw = row['period_label'].toString();

      spots.add(FlSpot(i.toDouble(), profit));
      labels[i] = _formatPeriodLabel(raw);
    }

    final double maxY = spots
        .map((e) => e.y)
        .fold<double>(0, (prev, y) => y > prev ? y : prev);

    final bool onlyOnePoint = spots.length == 1;

    return SizedBox(
      height: 240,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grafik Keuntungan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _period == 'daily'
                    ? 'Per Hari'
                    : _period == 'weekly'
                        ? 'Per Minggu'
                        : _period == 'monthly'
                            ? 'Per Bulan'
                            : 'Per Tahun',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    clipData: const FlClipData.all(),
                    minY: 0,
                    maxY: maxY <= 0 ? 1 : maxY * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval:
                          maxY <= 0 ? 1 : (maxY * 1.2 / 4).ceilToDouble(),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.black12),
                        bottom: BorderSide(color: Colors.black12),
                        right: BorderSide(color: Colors.transparent),
                        top: BorderSide(color: Colors.transparent),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _shortMoney(value),
                              style: const TextStyle(fontSize: 9),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (!labels.containsKey(index)) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(
                                  top: 4.0, right: 4.0),
                              child: Text(
                                labels[index]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            final label = labels[idx] ?? '';
                            return LineTooltipItem(
                              '$label\n${_money.format(spot.y)}',
                              const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: !onlyOnePoint,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: onlyOnePoint),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _primaryBlue.withOpacity(0.3),
                              _primaryBlue.withOpacity(0.0),
                            ],
                          ),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            _primaryBlue,
                            Colors.green.shade400,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  // ==== TOP PRODUK ====

  Widget _buildProductProfitSection() {
    if (_loadingProd && _profitProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _profitProducts.where((row) {
      final name = row['product_name']?.toString().toLowerCase() ?? '';
      if (_productSearch.isEmpty) return true;
      return name.contains(_productSearch.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Produk',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Produk dengan keuntungan tertinggi pada periode ini.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Cari produk...',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onChanged: (v) {
            setState(() {
              _productSearch = v;
            });
          },
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Text(
            'Belum ada data.',
            style: TextStyle(fontSize: 12),
          )
        else
          ...filtered.map((row) {
            final name = row['product_name']?.toString() ?? '';
            final profit =
                double.tryParse(row['total_profit'].toString()) ?? 0.0;
            final qty =
                int.tryParse(row['total_qty'].toString()) ?? 0;
            final sales =
                double.tryParse(row['total_sales'].toString()) ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.04),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () => _openProductDetail(row),
                leading: CircleAvatar(
                  backgroundColor: _primaryBlue.withOpacity(0.1),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: _primaryBlue,
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Terjual $qty pcs • Omzet ${_money.format(sales)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Profit',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      _money.format(profit),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  // ==== TOP KATEGORI ====

  Widget _buildCategoryProfitSection() {
    if (_loadingCat && _profitCategories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _profitCategories.where((row) {
      final name = row['category_name']?.toString().toLowerCase() ?? '';
      if (_categorySearch.isEmpty) return true;
      return name.contains(_categorySearch.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Kategori',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kategori dengan kontribusi keuntungan terbesar.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Cari kategori...',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onChanged: (v) {
            setState(() {
              _categorySearch = v;
            });
          },
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Text(
            'Belum ada data.',
            style: TextStyle(fontSize: 12),
          )
        else
          ...filtered.map((row) {
            final name = row['category_name']?.toString() ?? '';
            final profit =
                double.tryParse(row['total_profit'].toString()) ?? 0.0;
            final qty =
                int.tryParse(row['total_qty'].toString()) ?? 0;
            final sales =
                double.tryParse(row['total_sales'].toString()) ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.04),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () => _openCategoryDetail(row),
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.orange,
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Terjual $qty pcs • Omzet ${_money.format(sales)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Profit',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      _money.format(profit),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  // ---- TAB: KASBON ----

  Widget _buildKasbonTab() {
    if (_loadingKasbon && _kasbon.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_kasbon.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadKasbon,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('Tidak ada kasbon berjalan')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadKasbon,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _kasbon.length,
        itemBuilder: (context, index) {
          final row = _kasbon[index];

          final name = row['customer_name']?.toString() ?? '';
          final total =
              double.tryParse(row['total_amount'].toString()) ??
                  0.0;
          final paid =
              double.tryParse(row['paid_amount'].toString()) ?? 0.0;
          final remain = total - paid;

          String dateStr = '';
          try {
            final dt = DateTime.parse(
                row['created_at'].toString());
            dateStr = DateFormat('dd/MM/yyyy HH:mm').format(dt);
          } catch (_) {
            dateStr = row['created_at'].toString();
          }

          return Card(
            color: Colors.red.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              onTap: () => _openKasbonDetail(row),
              leading: const Icon(Icons.person),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '$dateStr\nTotal: ${_money.format(total)} • Dibayar: ${_money.format(paid)}',
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Sisa',
                    style: TextStyle(fontSize: 11),
                  ),
                  Text(
                    _money.format(remain),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
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

// helper row untuk detail produk
class _ProductTxnRow {
  final int saleId;
  final DateTime date;
  final String customerName;
  final int qty;
  final double subtotal;

  _ProductTxnRow({
    required this.saleId,
    required this.date,
    required this.customerName,
    required this.qty,
    required this.subtotal,
  });
}
