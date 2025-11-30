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

    final rootTheme = Theme.of(context);
    final isDark = rootTheme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xAA000000) : Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cardColor = theme.cardColor;
        final onSurface = theme.colorScheme.onSurface;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.55,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // HEADER
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _primaryBlue.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 20,
                              color: _primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detail Transaksi',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '#${sale.id}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dateFormatter.format(sale.createdAt),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontSize: 12,
                                          color: onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColorBg(sale),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isUtang
                                                ? Icons.warning_rounded
                                                : Icons.verified_rounded,
                                            size: 13,
                                            color: _statusColorText(sale),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _statusLabel(sale),
                                            style: TextStyle(
                                              color: _statusColorText(sale),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (sale.customerName != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant
                                .withOpacity(0.6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: onSurface.withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pelanggan',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontSize: 11,
                                        color: onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      sale.customerName!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // RINGKASAN
                      _buildSectionTitle('Ringkasan transaksi', theme),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total belanja',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _priceFormatter.format(sale.totalAmount),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 32,
                              color: theme.dividerColor,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total barang',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalQty pcs',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // LIST ITEM
                      _buildSectionTitle('Detail barang', theme),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                theme.dividerColor.withOpacity(0.8),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          itemCount: sale.items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 14),
                          itemBuilder: (context, index) {
                            final item = sale.items[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(
                                      right: 10, top: 4),
                                  decoration: BoxDecoration(
                                    color: _primaryBlue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryBlue,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.qty}x  ${_priceFormatter.format(item.price)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontSize: 12,
                                          color: onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _priceFormatter.format(item.subtotal),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: onSurface,
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

                      const SizedBox(height: 16),

                      // PEMBAYARAN
                      _buildSectionTitle('Rincian pembayaran', theme),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Belanja',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontSize: 13),
                                ),
                                Text(
                                  _priceFormatter.format(sale.totalAmount),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dibayar',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontSize: 13),
                                ),
                                Text(
                                  _priceFormatter.format(sale.paidAmount),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    color: onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kembalian',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontSize: 13),
                                ),
                                Text(
                                  _priceFormatter.format(sale.changeAmount),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    color: onSurface,
                                  ),
                                ),
                              ],
                            ),
                            if (isUtang) ...[
                              const SizedBox(height: 8),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sisa utang',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontSize: 13),
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
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Sisa ini akan tercatat sebagai utang pelanggan.',
                                  style:
                                      theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ============= BUILD =============

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sales.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadSales,
        child: ListView(
          children: [
            const SizedBox(height: 200),
            Center(
              child: Text(
                'Belum ada riwayat transaksi',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onSurface,
                ),
              ),
            ),
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

          // TAB FILTER (All / Lunas / Utang)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.6)
                    : const Color(0xFFF3F6FF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTabChip(0, 'Semua', theme),
                  _buildTabChip(1, 'Lunas', theme),
                  _buildTabChip(2, 'Utang', theme),
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
                      color: theme.cardColor,
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
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: onSurface,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColorBg(sale),
                                        borderRadius:
                                            BorderRadius.circular(20),
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
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // nama pelanggan atau placeholder
                                Text(
                                  sale.customerName ?? 'Pelanggan umum',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: onSurface,
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

  Widget _buildTabChip(int index, String label, ThemeData theme) {
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
            color: isActive ? theme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? _primaryBlue
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
