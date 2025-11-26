import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'sales_page.dart';
import 'products_page.dart';
import 'sales_history_page.dart';
import 'reports_page.dart';
import 'customers_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onUserActivity;
  final VoidCallback onForceLogout;

  const HomePage({
    super.key,
    required this.onUserActivity,
    required this.onForceLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _bottomIndex = 2; // default buka Manajemen Produk

  static const Color _primaryBlue = Color(0xFF57A0D3);

  void _handleUserActivity() {
    widget.onUserActivity();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleUserActivity,
      onPanDown: (_) => _handleUserActivity(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FF),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            _getTitleForIndex(_bottomIndex),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _openSettingSheet,
              icon: const Icon(Icons.settings, color: Colors.black),
            )
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bottomItem(
                  icon: Icons.history,
                  label: 'Riwayat',
                  index: 0,
                ),
                _bottomItem(
                  icon: Icons.shopping_cart,
                  label: 'Transaksi',
                  index: 1,
                ),
                _centerProductItem(),
                _bottomItem(
                  icon: Icons.bar_chart,
                  label: 'Keuangan',
                  index: 3,
                ),
                _bottomItem(
                  icon: Icons.people,
                  label: 'Pelanggan',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Riwayat Transaksi';
      case 1:
        return 'Transaksi Penjualan';
      case 2:
        return 'Manajemen Produk';
      case 3:
        return 'Laporan Keuangan';
      case 4:
        return 'Pelanggan';
      default:
        return 'Kasir Pintar';
    }
  }

  Widget _buildBody() {
    switch (_bottomIndex) {
      case 0:
        return SalesHistoryPage(onUserActivity: _handleUserActivity);
      case 1:
        return SalesPage(onUserActivity: _handleUserActivity);
      case 2:
        return ProductsPage(onUserActivity: _handleUserActivity);
      case 3:
        return ReportsPage(onUserActivity: _handleUserActivity);
      case 4:
        return CustomersPage(onUserActivity: _handleUserActivity);
      default:
        return _dashboardContent();
    }
  }

  Widget _dashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Balance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          const Text(
            "\$12,549.00",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ["Aug", "Sep", "Oct", "Nov", "Dec"];
                        return Text(
                          months[value.toInt() % 5],
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: [
                  _bar(0, 12),
                  _bar(1, 18),
                  _bar(2, 14),
                  _bar(3, 20),
                  _bar(4, 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 22,
          borderRadius: BorderRadius.circular(10),
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _bottomItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _bottomIndex == index;

    return GestureDetector(
      onTap: () {
        _handleUserActivity();
        setState(() {
          _bottomIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerProductItem() {
    final isActive = _bottomIndex == 2;

    return GestureDetector(
      onTap: () {
        _handleUserActivity();
        setState(() {
          _bottomIndex = 2;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                  color: Colors.black.withOpacity(0.25),
                )
              ],
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: _primaryBlue,
              size: 30,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Produk',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  void _openSettingSheet() {
    _handleUserActivity();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _settingItem(Icons.person, "Data Pribadi"),
              _settingItem(Icons.photo_camera, "Ganti Foto Profil"),
              _settingItem(Icons.color_lens, "Ganti Tema"),
              _settingItem(
                Icons.logout,
                "Logout",
                onTap: widget.onForceLogout,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _settingItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: _primaryBlue),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        _handleUserActivity();
        Navigator.pop(context);
        if (onTap != null) onTap();
      },
    );
  }
}
