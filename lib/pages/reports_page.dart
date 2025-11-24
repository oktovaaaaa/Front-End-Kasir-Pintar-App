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
      final data = await _reportService.getProfitByProduct();
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
      final data = await _reportService.getProfitByCategory();
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

  // ==== Kasbon detail ====

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

  // ==== UI ====

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
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

    return RefreshIndicator(
      onRefresh: _loadAllReports,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 12),
          _buildSummaryCards(totalProfit, totalSales, totalTrx),
          const SizedBox(height: 12),
          _buildProfitChart(),
          const SizedBox(height: 16),
          _buildProductProfitList(),
          const SizedBox(height: 16),
          _buildCategoryProfitList(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _periodChip('daily', 'Harian'),
        const SizedBox(width: 6),
        _periodChip('weekly', 'Mingguan'),
        const SizedBox(width: 6),
        _periodChip('monthly', 'Bulanan'),
        const SizedBox(width: 6),
        _periodChip('yearly', 'Tahunan'),
      ],
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
      },
    );
  }

  Widget _buildSummaryCards(
      double totalProfit, double totalSales, int totalTrx) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Total Keuntungan',
            value: _money.format(totalProfit),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            title: 'Total Penjualan',
            value: _money.format(totalSales),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            title: 'Transaksi',
            value: '$totalTrx',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
      {required String title,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitChart() {
    if (_summary.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Text('Belum ada data untuk grafik'),
      );
    }

    final spots = <FlSpot>[];
    final labels = <int, String>{};

    for (int i = 0; i < _summary.length; i++) {
      final row = _summary[i];
      final profit =
          double.tryParse(row['total_profit'].toString()) ?? 0.0;

      // label tanggal (pakai substring tanggal saja biar simple)
      final raw = row['period_label'].toString();
      String label;
      try {
        final dt = DateTime.parse(raw);
        label = DateFormat('dd/MM').format(dt);
      } catch (_) {
        label = raw.toString();
      }

      spots.add(FlSpot(i.toDouble(), profit));
      labels[i] = label;
    }

    final double maxY = spots
        .map((e) => e.y)
        .fold<double>(0, (prev, y) => y > prev ? y : prev);

    return SizedBox(
      height: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY <= 0 ? 1 : maxY * 1.2,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (!labels.containsKey(index)) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        labels[index]!,
                        style: const TextStyle(fontSize: 9),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY <= 0 ? 1 : maxY / 4,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _shortMoney(value),
                        style: const TextStyle(fontSize: 8),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
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

  Widget _buildProductProfitList() {
    if (_loadingProd && _profitProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keuntungan per Produk',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (_profitProducts.isEmpty)
          const Text('Belum ada data.')
        else
          ..._profitProducts.map((row) {
            final name = row['product_name']?.toString() ?? '';
            final profit = double.tryParse(
                    row['total_profit'].toString()) ??
                0.0;
            final qty =
                int.tryParse(row['total_qty'].toString()) ?? 0;
            final sales =
                double.tryParse(row['total_sales'].toString()) ??
                    0.0;

            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              subtitle: Text(
                  'Terjual $qty pcs • Omzet ${_money.format(sales)}'),
              trailing: Text(
                _money.format(profit),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildCategoryProfitList() {
    if (_loadingCat && _profitCategories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keuntungan per Kategori',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (_profitCategories.isEmpty)
          const Text('Belum ada data.')
        else
          ..._profitCategories.map((row) {
            final name = row['category_name']?.toString() ?? '';
            final profit = double.tryParse(
                    row['total_profit'].toString()) ??
                0.0;
            final qty =
                int.tryParse(row['total_qty'].toString()) ?? 0;
            final sales =
                double.tryParse(row['total_sales'].toString()) ??
                    0.0;

            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              subtitle: Text(
                  'Terjual $qty pcs • Omzet ${_money.format(sales)}'),
              trailing: Text(
                _money.format(profit),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
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
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => _openKasbonDetail(row),
              leading: const Icon(Icons.person),
              title: Text(name),
              subtitle: Text(
                  '$dateStr\nTotal: ${_money.format(total)} • Dibayar: ${_money.format(paid)}'),
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
