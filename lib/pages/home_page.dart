import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'sales_page.dart';
import 'products_page.dart';
import 'sales_history_page.dart';
import 'reports_page.dart';
import 'customers_page.dart';
import 'edit_profile_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onUserActivity;
  final VoidCallback onForceLogout;

  // untuk kontrol theme dari root
  final ValueChanged<bool>? onThemeChanged;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.onUserActivity,
    required this.onForceLogout,
    this.onThemeChanged,
    this.isDarkMode = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _bottomIndex = 2; // default buka Manajemen Produk

  static const Color _primaryBlue = Color(0xFF57A0D3);

  bool _localDark = false;

  @override
  void initState() {
    super.initState();
    _localDark = widget.isDarkMode;
  }

  void _handleUserActivity() {
    widget.onUserActivity();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // warna background bottom bar ikut tema
    final Color bottomBarColor =
        isDark ? theme.colorScheme.surface.withOpacity(0.98) : _primaryBlue;

    return GestureDetector(
      onTap: _handleUserActivity,
      onPanDown: (_) => _handleUserActivity(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            _getTitleForIndex(_bottomIndex),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _openSettingSheet,
              icon: Icon(
                Icons.settings,
                color: theme.iconTheme.color ?? theme.colorScheme.onSurface,
              ),
            )
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bottomBarColor,
            borderRadius: const BorderRadius.only(
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
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Balance",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "\$12,549.00",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
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
                        final theme = Theme.of(context);
                        const months = ["Aug", "Sep", "Oct", "Nov", "Dec"];
                        return Text(
                          months[value.toInt() % 5],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color activeIconColor = Colors.white;
    final Color inactiveIconColor = isDark
        ? Colors.white.withOpacity(0.65)
        : Colors.white.withOpacity(0.85);

    final Color activeBgColor = isDark
        ? Colors.white.withOpacity(0.16)
        : Colors.white.withOpacity(0.26);

    return GestureDetector(
      onTap: () {
        _handleUserActivity();
        setState(() {
          _bottomIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? activeIconColor : inactiveIconColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeIconColor : inactiveIconColor,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerProductItem() {
    final isActive = _bottomIndex == 2;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color shadowColor =
        isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.25);

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
                  color: shadowColor,
                )
              ],
            ),
            child: const Icon(
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

  // =========================
  // BOTTOM SHEET PENGATURAN
  // =========================
  void _openSettingSheet() {
    _handleUserActivity();

    final theme = Theme.of(context);
    final isDarkGlobal = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      // bedakan warna background untuk light vs dark
      backgroundColor: isDarkGlobal ? const Color(0xFF020617) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final isDark = sheetTheme.brightness == Brightness.dark;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                      color: sheetTheme.dividerColor
                          .withOpacity(isDark ? 0.6 : 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // JUDUL
                Text(
                  "Pengaturan",
                  style: sheetTheme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: sheetTheme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // SECTION: Data Diri
                Text(
                  "Data Diri",
                  style: sheetTheme.textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    // agak terang biar kebaca di dark
                    color: sheetTheme.colorScheme.onSurface
                        .withOpacity(isDark ? 0.8 : 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                _settingItem(
                  Icons.person,
                  "Edit Profil",
                  onTap: () {
                    Navigator.push(
                      sheetContext,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // SECTION: Tampilan
                Text(
                  "Tampilan",
                  style: sheetTheme.textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    color: sheetTheme.colorScheme.onSurface
                        .withOpacity(isDark ? 0.8 : 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Icon(
                    Icons.dark_mode_outlined,
                    color: _primaryBlue,
                  ),
                  title: Text(
                    "Mode Gelap",
                    style: sheetTheme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: sheetTheme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: Switch(
                    // nilai switch ikut theme sekarang
                    value: isDarkGlobal,
                    activeColor: _primaryBlue,
                    onChanged: (value) {
                      setState(() {
                        _localDark = value;
                      });
                      // trigger ke main.dart
                      widget.onThemeChanged?.call(value);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // SECTION: Akun
                Text(
                  "Akun",
                  style: sheetTheme.textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    color: sheetTheme.colorScheme.onSurface
                        .withOpacity(isDark ? 0.8 : 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                _settingItem(
                  Icons.logout,
                  "Logout",
                  onTap: widget.onForceLogout,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _settingItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? theme.iconTheme.color ?? _primaryBlue,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          color: textColor ?? theme.colorScheme.onSurface,
        ),
      ),
      onTap: () {
        _handleUserActivity();
        Navigator.pop(context); // tutup bottom sheet
        if (onTap != null) onTap();
      },
    );
  }
}
