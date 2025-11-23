import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
  int _bottomIndex = 0;

  void _handleUserActivity() {
    widget.onUserActivity();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // setiap user gerak di layar, timer di-reset
      onTap: _handleUserActivity,
      onPanDown: (_) => _handleUserActivity(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FF),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text(
            "Statistic",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                _openSettingSheet();
              },
              icon: const Icon(Icons.settings, color: Colors.black),
            )
          ],
        ),

        // BODY
        body: SingleChildScrollView(
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

              // GRAFIK
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
                            return Text(months[value.toInt() % 5]);
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
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

              const SizedBox(height: 25),

              // INCOME & OUTCOME
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title: "Income",
                      amount: "\$5,440",
                      color: Colors.blue,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      title: "Outcome",
                      amount: "\$2,209",
                      color: Colors.red,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () {
            _handleUserActivity();
            // nanti ini buat tambah transaksi
          },
          child: const Icon(Icons.add, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bottomItem(Icons.home, "Home", 0),
                _bottomItem(Icons.shopping_cart, "Transaksi", 1),
                const SizedBox(width: 35),
                _bottomItem(Icons.money, "Kasbon", 2),
                _bottomItem(Icons.pie_chart, "Laporan", 3),
              ],
            ),
          ),
        ),
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

  Widget _summaryCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomItem(IconData icon, String label, int index) {
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
          Icon(icon, color: _bottomIndex == index ? Colors.blue : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: _bottomIndex == index ? Colors.blue : Colors.grey,
              fontSize: 12,
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
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        _handleUserActivity();
        Navigator.pop(context);
        if (onTap != null) onTap();
      },
    );
  }
}
