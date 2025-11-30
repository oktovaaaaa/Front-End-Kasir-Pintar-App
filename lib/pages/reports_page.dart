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
  String _chartType = 'line'; // 'line' atau 'bar'

  bool _loadingSummary = false;
  bool _loadingProd = false;
  bool _loadingCat = false;
  bool _loadingKasbon = false;

  List<Map<String, dynamic>> _summary = [];
  List<Map<String, dynamic>> _profitProducts = [];
  List<Map<String, dynamic>> _profitCategories = [];
  List<Map<String, dynamic>> _kasbon = [];

  // === GLOBAL SEARCH UNTUK PRODUK & KATEGORI ===
  String _globalSearch = '';

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

  // ========= HELPER FORMAT =========

  String _formatPeriodLabel(String rawLabel) {
    return formatPeriodLabelByPeriod(rawLabel, _period);
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

  // ========= UI UTAMA =========

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF020617), const Color(0xFF020617)]
              : [_primaryBlue.withOpacity(0.08), Colors.white],
        ),
      ),
      child: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildMainSegmentedTab(),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildProfitTab(),
                    _buildKasbonTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab atas: Laporan / Kasbon (segmented)
  Widget _buildMainSegmentedTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: _primaryBlue,
        unselectedLabelColor:
            isDark ? Colors.white70 : _primaryBlue.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Laporan'),
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
          prev + (double.tryParse(row['total_profit'].toString()) ?? 0.0),
    );
    final totalSales = _summary.fold<double>(
      0,
      (prev, row) =>
          prev + (double.tryParse(row['total_sales'].toString()) ?? 0.0),
    );
    final totalTrx = _summary.fold<int>(
      0,
      (prev, row) => prev + (int.tryParse(row['transaksi'].toString()) ?? 0),
    );
    final totalQty = _profitProducts.fold<int>(
      0,
      (prev, row) =>
          prev + (int.tryParse(row['total_qty'].toString()) ?? 0),
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
          const SizedBox(height: 14),
          _buildChartTypeSwitcher(),
          const SizedBox(height: 8),
          _buildProfitChart(),
          const SizedBox(height: 16),

          // === GLOBAL SEARCH FIELD (untuk Produk & Kategori) ===
          _buildGlobalSearchField(),
          const SizedBox(height: 12),

          _buildProductProfitSection(),
          const SizedBox(height: 16),
          _buildCategoryProfitSection(),
        ],
      ),
    );
  }

  // selector periode (dropdown)
  Widget _buildPeriodSelector() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Statistic',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                  _loadProductProfit();
                  _loadCategoryProfit();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // switch Line / Bar chart
  Widget _buildChartTypeSwitcher() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _chartTypeChip('line', 'Line'),
          _chartTypeChip('bar', 'Bar'),
        ],
      ),
    );
  }

  Widget _chartTypeChip(String type, String label) {
    final bool active = _chartType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!active) {
            setState(() => _chartType = type);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _primaryBlue : _primaryBlue.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  // grid 4 kartu ringkasan
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
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
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

  // ---- CHART PROFIT (LINE / BAR) ----

  Widget _buildProfitChart() {
    final theme = Theme.of(context);

    if (_summary.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text(
          'Belum ada data untuk grafik',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      );
    }

    final profits = <double>[];
    final sales = <double>[];
    final labels = <int, String>{};

    for (int i = 0; i < _summary.length; i++) {
      final row = _summary[i];
      final profit =
          double.tryParse(row['total_profit'].toString()) ?? 0.0;
      final sale = double.tryParse(row['total_sales'].toString()) ?? 0.0;
      final raw = row['period_label'].toString();

      profits.add(profit);
      sales.add(sale);
      labels[i] = _formatPeriodLabel(raw);
    }

    final double maxProfit =
        profits.fold<double>(0, (p, e) => e > p ? e : p);
    final double maxSales =
        sales.fold<double>(0, (p, e) => e > p ? e : p);
    final double maxY = (maxProfit > maxSales ? maxProfit : maxSales);

    final bool onlyOnePoint = profits.length == 1;

    return SizedBox(
      height: 260,
      child: Card(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _chartType == 'line'
                    ? LineChart(
                        LineChartData(
                          clipData: const FlClipData.all(),
                          minY: 0,
                          maxY: maxY <= 0 ? 1 : maxY * 1.2,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxY <= 0
                                ? 1
                                : (maxY * 1.2 / 4).ceilToDouble(),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: const Border(
                              left: BorderSide(color: Colors.black12),
                              bottom: BorderSide(color: Colors.black12),
                              right:
                                  BorderSide(color: Colors.transparent),
                              top: BorderSide(color: Colors.transparent),
                            ),
                          ),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
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
                            // garis omzet (sales)
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < profits.length; i++)
                                  FlSpot(i.toDouble(), sales[i]),
                              ],
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
                                  _primaryBlue.withOpacity(0.7),
                                ],
                              ),
                            ),
                            // garis profit
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < profits.length; i++)
                                  FlSpot(i.toDouble(), profits[i]),
                              ],
                              isCurved: !onlyOnePoint,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: onlyOnePoint),
                              belowBarData: BarAreaData(show: false),
                              color: Colors.green,
                            ),
                          ],
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          maxY: maxY <= 0 ? 1 : maxY * 1.2,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxY <= 0
                                ? 1
                                : (maxY * 1.2 / 4).ceilToDouble(),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
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
                          barGroups: [
                            for (int i = 0; i < profits.length; i++)
                              BarChartGroupData(
                                x: i,
                                barsSpace: 4,
                                barRods: [
                                  BarChartRodData(
                                    toY: sales[i],
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    width: 8,
                                    color: _primaryBlue,
                                  ),
                                  BarChartRodData(
                                    toY: profits[i],
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    width: 8,
                                    color: Colors.green.withOpacity(0.9),
                                  ),
                                ],
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

  // ========= DETAIL KARTU RINGKASAN (BOTTOM SHEET) =========

  void _openOverviewDetail(String type) {
    widget.onUserActivity();

    final totalProfit = _summary.fold<double>(
      0,
      (prev, row) =>
          prev + (double.tryParse(row['total_profit'].toString()) ?? 0.0),
    );
    final totalSales = _summary.fold<double>(
      0,
      (prev, row) =>
          prev + (double.tryParse(row['total_sales'].toString()) ?? 0.0),
    );
    final totalTrx = _summary.fold<int>(
      0,
      (prev, row) =>
          prev + (int.tryParse(row['transaksi'].toString()) ?? 0),
    );
    final totalQty = _profitProducts.fold<int>(
      0,
      (prev, row) =>
          prev + (int.tryParse(row['total_qty'].toString()) ?? 0),
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
              final profit =
                  double.tryParse(row['total_profit'].toString()) ?? 0.0;
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
                color: _primaryBlue,
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
              final sales =
                  double.tryParse(row['total_sales'].toString()) ?? 0.0;
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
                    color: _primaryBlue,
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
              final sales =
                  double.tryParse(row['total_sales'].toString()) ?? 0.0;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(name),
                subtitle: Text(
                    'Terjual $qty pcs • Omzet ${_money.format(sales)}'),
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

  // === GLOBAL SEARCH FIELD ===
  Widget _buildGlobalSearchField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Produk',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Produk dengan keuntungan tertinggi pada periode ini.',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Cari produk atau kategori...',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onChanged: (v) {
            setState(() {
              _globalSearch = v;
            });
          },
        ),
      ],
    );
  }

  // ==== TOP PRODUK (dengan detail timeline) ====

  Widget _buildProductProfitSection() {
    final theme = Theme.of(context);

    if (_loadingProd && _profitProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _profitProducts.where((row) {
      final name = row['product_name']?.toString().toLowerCase() ?? '';
      if (_globalSearch.isEmpty) return true;
      return name.contains(_globalSearch.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_globalSearch.isEmpty)
          const SizedBox.shrink(),
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
                color: theme.cardColor,
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

  Future<void> _openProductDetail(Map<String, dynamic> row) async {
    widget.onUserActivity();

    final int productId =
        int.tryParse(row['product_id'].toString()) ?? 0;
    if (productId == 0) return;

    try {
      // semua transaksi untuk produk ini
      final sales = await _saleService.getSales();
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

      // timeline awal pakai periode yang sama dengan laporan utama
      final initialTimeline =
          await _reportService.getProductTimeline(productId, _period);

      String sheetPeriod = _period;
      String sheetChartType = 'line';
      List<Map<String, dynamic>> sheetTimeline = initialTimeline;
      bool loadingTimeline = false;

      final int totalQty =
          int.tryParse(row['total_qty'].toString()) ?? 0;
      final double totalSales =
          double.tryParse(row['total_sales'].toString()) ?? 0.0;
      final double totalProfit =
          double.tryParse(row['total_profit'].toString()) ?? 0.0;
      final String productName =
          row['product_name']?.toString() ?? '';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> reloadTimeline(String newPeriod) async {
                setSheetState(() {
                  loadingTimeline = true;
                });
                try {
                  final data = await _reportService.getProductTimeline(
                      productId, newPeriod);
                  setSheetState(() {
                    sheetPeriod = newPeriod;
                    sheetTimeline = data;
                  });
                } catch (e) {
                  _showSnack('Gagal memuat timeline produk: $e');
                } finally {
                  setSheetState(() {
                    loadingTimeline = false;
                  });
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + 16,
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
                          margin:
                              const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
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
                        'Terjual $totalQty pcs • Omzet ${_money.format(totalSales)} • Profit ${_money.format(totalProfit)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      // filter periode detail produk
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _detailPeriodChip(
                                sheetPeriod, 'daily', 'Harian',
                                (val) => reloadTimeline(val),
                                setSheetState),
                            _detailPeriodChip(
                                sheetPeriod, 'weekly', 'Mingguan',
                                (val) => reloadTimeline(val),
                                setSheetState),
                            _detailPeriodChip(
                                sheetPeriod, 'monthly', 'Bulanan',
                                (val) => reloadTimeline(val),
                                setSheetState),
                            _detailPeriodChip(
                                sheetPeriod, 'yearly', 'Tahunan',
                                (val) => reloadTimeline(val),
                                setSheetState),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // switch chart type
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _detailChartChip(sheetChartType, 'line',
                                'Line', setSheetState),
                            _detailChartChip(sheetChartType, 'bar',
                                'Bar', setSheetState),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // chart timeline
                      if (loadingTimeline)
                        const SizedBox(
                          height: 200,
                          child: Center(
                              child: CircularProgressIndicator()),
                        )
                      else
                        _buildTimelineChart(
                          sheetTimeline,
                          sheetPeriod,
                          sheetChartType,
                        ),
                      const SizedBox(height: 12),

                      const Text(
                        'Transaksi Produk',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        height: 260,
                        child: txns.isEmpty
                            ? const Center(
                                child: Text(
                                    'Belum ada transaksi untuk produk ini'),
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
                                    contentPadding:
                                        EdgeInsets.zero,
                                    title: Text(dateStr),
                                    subtitle: Text(
                                        'Pelanggan: ${t.customerName}\nQty: ${t.qty} pcs'),
                                    isThreeLine: true,
                                    trailing: Text(
                                      _money.format(t.subtotal),
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      _showSnack('Gagal memuat detail produk: $e');
    }
  }

  Widget _detailPeriodChip(
    String current,
    String value,
    String label,
    Future<void> Function(String) onChange,
    void Function(void Function()) setSheetState,
  ) {
    final selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!selected) {
            onChange(value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color:
                  selected ? _primaryBlue : _primaryBlue.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailChartChip(
    String current,
    String value,
    String label,
    void Function(void Function()) setSheetState,
  ) {
    final selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!selected) {
            setSheetState(() {
              // rubah chart type di bottom sheet
              current = value;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color:
                  selected ? _primaryBlue : _primaryBlue.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineChart(
    List<Map<String, dynamic>> timeline,
    String period,
    String chartType,
  ) {
    if (timeline.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Belum ada data timeline.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      );
    }

    final profits = <double>[];
    final labels = <int, String>{};

    for (int i = 0; i < timeline.length; i++) {
      final row = timeline[i];
      final profit =
          double.tryParse(row['total_profit'].toString()) ?? 0.0;
      final raw = row['period_label'].toString();
      profits.add(profit);
      labels[i] = formatPeriodLabelByPeriod(raw, period);
    }

    final double maxY =
        profits.fold<double>(0, (p, e) => e > p ? e : p);
    final bool onlyOnePoint = profits.length == 1;

    if (chartType == 'bar') {
      return SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxY <= 0 ? 1 : maxY * 1.2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY <= 0
                  ? 1
                  : (maxY * 1.2 / 4).ceilToDouble(),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
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
                      padding:
                          const EdgeInsets.only(top: 4.0, right: 4.0),
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
            barGroups: [
              for (int i = 0; i < profits.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: profits[i],
                      width: 14,
                      borderRadius: BorderRadius.circular(6),
                      color: _primaryBlue,
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    // line chart
    return SizedBox(
      height: 200,
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
                    padding:
                        const EdgeInsets.only(top: 4.0, right: 4.0),
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
              spots: [
                for (int i = 0; i < profits.length; i++)
                  FlSpot(i.toDouble(), profits[i]),
              ],
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
                    _primaryBlue.withOpacity(0.35),
                    _primaryBlue.withOpacity(0.0),
                  ],
                ),
              ),
              color: _primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  // ==== TOP KATEGORI ====

  Widget _buildCategoryProfitSection() {
    final theme = Theme.of(context);

    if (_loadingCat && _profitCategories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _profitCategories.where((row) {
      final name =
          row['category_name']?.toString().toLowerCase() ?? '';
      if (_globalSearch.isEmpty) return true;
      return name.contains(_globalSearch.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Kategori',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kategori dengan kontribusi keuntungan terbesar.',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
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
                color: theme.cardColor,
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

  Future<void> _openCategoryDetail(Map<String, dynamic> row) async {
    widget.onUserActivity();

    final int categoryId =
        int.tryParse(row['category_id'].toString()) ?? 0;
    if (categoryId == 0) return;

    try {
      final initialTimeline =
          await _reportService.getCategoryTimeline(categoryId, _period);

      String sheetPeriod = _period;
      String sheetChartType = 'line';
      List<Map<String, dynamic>> sheetTimeline = initialTimeline;
      bool loadingTimeline = false;

      final int totalQty =
          int.tryParse(row['total_qty'].toString()) ?? 0;
      final double totalSales =
          double.tryParse(row['total_sales'].toString()) ?? 0.0;
      final double profit =
          double.tryParse(row['total_profit'].toString()) ?? 0.0;
      final String categoryName =
          row['category_name']?.toString() ?? '';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> reloadTimeline(String newPeriod) async {
                setSheetState(() {
                  loadingTimeline = true;
                });
                try {
                  final data = await _reportService.getCategoryTimeline(
                      categoryId, newPeriod);
                  setSheetState(() {
                    sheetPeriod = newPeriod;
                    sheetTimeline = data;
                  });
                } catch (e) {
                  _showSnack('Gagal memuat timeline kategori: $e');
                } finally {
                  setSheetState(() {
                    loadingTimeline = false;
                  });
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + 16,
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
                          margin:
                              const EdgeInsets.only(bottom: 12),
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
                        'Terjual $totalQty pcs • Omzet ${_money.format(totalSales)} • Profit ${_money.format(profit)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _detailPeriodChip(
                                sheetPeriod, 'daily', 'Harian',
                                (val) => reloadTimeline(val),
                                setSheetState),
                            _detailPeriodChip(
                                sheetPeriod, 'weekly', 'Mingguan',
                                (val) => reloadTimeline(val),
                                setSheetState),
                            _detailPeriodChip(
                                sheetPeriod, 'monthly', 'Bulanan',
                                (val) => reloadTimeline(val),
                                setSheetState),
                            _detailPeriodChip(
                                sheetPeriod, 'yearly', 'Tahunan',
                                (val) => reloadTimeline(val),
                                setSheetState),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _detailChartChip(sheetChartType, 'line',
                                'Line', setSheetState),
                            _detailChartChip(sheetChartType, 'bar',
                                'Bar', setSheetState),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (loadingTimeline)
                        const SizedBox(
                          height: 200,
                          child: Center(
                              child: CircularProgressIndicator()),
                        )
                      else
                        _buildTimelineChart(
                          sheetTimeline,
                          sheetPeriod,
                          sheetChartType,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      _showSnack('Gagal memuat detail kategori: $e');
    }
  }

  // ---- TAB: KASBON ----

  Widget _buildKasbonTab() {
    final theme = Theme.of(context);

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
              double.tryParse(row['total_amount'].toString()) ?? 0.0;
          final paid =
              double.tryParse(row['paid_amount'].toString()) ?? 0.0;
          final remain = total - paid;

          String dateStr = '';
          try {
            final dt =
                DateTime.parse(row['created_at'].toString());
            dateStr = DateFormat('dd/MM/yyyy HH:mm').format(dt);
          } catch (_) {
            dateStr = row['created_at'].toString();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ${_money.format(total)} • Dibayar: ${_money.format(paid)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money.format(remain),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () =>
                              _openKasbonPaySheet(row),
                          child: const Text(
                            'Bayar',
                            style: TextStyle(
                                fontSize: 11, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openKasbonPaySheet(
      Map<String, dynamic> row) async {
    widget.onUserActivity();

    final int saleId = int.tryParse(row['id'].toString()) ?? 0;
    final double total =
        double.tryParse(row['total_amount'].toString()) ?? 0.0;
    final double paid =
        double.tryParse(row['paid_amount'].toString()) ?? 0.0;
    final double remain = total - paid;

    final formatter = NumberFormat.decimalPattern('id_ID');
    final controller = TextEditingController(
      text: formatter.format(remain.toInt()),
    );

    final result = await showModalBottomSheet<bool>(
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
              const Text(
                'Bayar Kasbon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${_money.format(total)}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Sudah dibayar: ${_money.format(paid)}',
                style: const TextStyle(fontSize: 12),
              ),
              RichText(
                text: TextSpan(
                  text: 'Sisa: ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: _money.format(remain),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal bayar',
                  hintText: 'Nominal yang akan dibayar',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Simpan Pembayaran',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      final text =
          controller.text.replaceAll('.', '').replaceAll(',', '');
      final bayar = double.tryParse(text) ?? 0;

      if (bayar <= 0) {
        _showSnack('Nominal bayar harus lebih dari 0');
        return;
      }
      if (bayar > remain) {
        _showSnack('Tidak boleh melebihi sisa utang');
        return;
      }

      try {
        await _saleService.payKasbon(
          saleId: saleId,
          amount: bayar,
        );

        _showSnack('Kasbon berhasil diperbarui');
        _loadKasbon();
      } catch (e) {
        _showSnack('Gagal menyimpan pembayaran: $e');
      }
    }
  }
}

// helper row untuk detail transaksi produk
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

/// helper global untuk format label periode (biar bisa dipakai di detail)
String formatPeriodLabelByPeriod(String rawLabel, String period) {
  try {
    final dt = DateTime.parse(rawLabel);

    switch (period) {
      case 'weekly':
        final endOfWeek = dt.add(const Duration(days: 6));
        final start = DateFormat('dd/MM').format(dt);
        final end = DateFormat('dd/MM').format(endOfWeek);
        return '$start\n$end';
      case 'monthly':
        return DateFormat('MMM yy', 'id_ID').format(dt);
      case 'yearly':
        return DateFormat('yyyy').format(dt);
      case 'daily':
      default:
        return DateFormat('dd/MM').format(dt);
    }
  } catch (_) {
    return rawLabel;
  }
}
