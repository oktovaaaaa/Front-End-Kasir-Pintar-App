import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/sale.dart';
import '../services/customer_service.dart';
import '../services/sale_service.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  final VoidCallback onUserActivity;

  const CustomerDetailPage({
    super.key,
    required this.customer,
    required this.onUserActivity,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final CustomerService _customerService = CustomerService();
  final SaleService _saleService = SaleService();

  static const Color _primaryBlue = Color(0xFF57A0D3);

  final NumberFormat _priceFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final DateFormat _dateFormatter =
      DateFormat('dd MMM yyyy • HH:mm', 'id_ID');

  bool _isLoadingSales = false;
  List<Sale> _sales = [];

  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoadingSales = true);
    try {
      final allSales = await _saleService.getSales();

      _sales = allSales
          .where((s) =>
              (s.customerName ?? '').toLowerCase() ==
              _customer.name.toLowerCase())
          .toList();
    } catch (e) {
      _showSnack('Gagal memuat transaksi: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSales = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ======= RINGKASAN ANGKA =======

  double get _totalBelanja =>
      _sales.fold(0.0, (p, s) => p + s.totalAmount);

  double get _totalDibayar =>
      _sales.fold(0.0, (p, s) => p + s.paidAmount);

  double get _totalUtang => _sales.fold(0.0, (p, s) {
        if (s.status == 'kasbon') {
          final sisa = s.totalAmount - s.paidAmount;
          return p + (sisa > 0 ? sisa : 0);
        }
        return p;
      });

  int get _jumlahTransaksi => _sales.length;

  // ======= EDIT & HAPUS =======

  Future<void> _openEditForm() async {
    widget.onUserActivity();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nameController = TextEditingController(text: _customer.name);
    final emailController = TextEditingController(text: _customer.email ?? '');
    final phoneController = TextEditingController(text: _customer.phone ?? '');
    final addressController =
        TextEditingController(text: _customer.address ?? '');
    final companyController =
        TextEditingController(text: _customer.company ?? '');
    final noteController = TextEditingController(text: _customer.note ?? '');

    final formKey = GlobalKey<FormState>();

    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final sheetIsDark = sheetTheme.brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
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
                            .withOpacity(sheetIsDark ? 0.7 : 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: sheetTheme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Edit Pelanggan',
                          style: sheetTheme.textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: sheetTheme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perbarui informasi pelanggan agar data kasir selalu rapi dan terbaru.',
                    style: sheetTheme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: sheetTheme.colorScheme.onSurface
                          .withOpacity(sheetIsDark ? 0.7 : 0.6),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _editField(
                    label: 'Nama lengkap',
                    controller: nameController,
                    icon: Icons.badge_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  _editField(
                    label: 'No. Telepon',
                    controller: phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  _editField(
                    label: 'Email (opsional)',
                    controller: emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _editField(
                    label: 'Alamat (opsional)',
                    controller: addressController,
                    icon: Icons.location_on_outlined,
                  ),
                  _editField(
                    label: 'Instansi/Perusahaan (opsional)',
                    controller: companyController,
                    icon: Icons.apartment_outlined,
                  ),
                  _editField(
                    label: 'Catatan (opsional)',
                    controller: noteController,
                    icon: Icons.sticky_note_2_outlined,
                  ),

                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop<bool>(sheetContext, false),
                        child: Text(
                          'Batal',
                          style: sheetTheme.textTheme.bodyMedium?.copyWith(
                            color: sheetTheme.colorScheme.onSurface
                                .withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          backgroundColor: sheetTheme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          try {
                            await _customerService.updateCustomer(
                              id: _customer.id,
                              name: nameController.text.trim(),
                              email: emailController.text.trim().isEmpty
                                  ? null
                                  : emailController.text.trim(),
                              phone: phoneController.text.trim().isEmpty
                                  ? null
                                  : phoneController.text.trim(),
                              address: addressController.text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : addressController.text.trim(),
                              company: companyController.text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : companyController.text.trim(),
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                            );

                            setState(() {
                              _customer = _customer.copyWith(
                                name: nameController.text.trim(),
                                email: emailController.text.trim().isEmpty
                                    ? null
                                    : emailController.text.trim(),
                                phone: phoneController.text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : phoneController.text.trim(),
                                address: addressController.text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : addressController.text.trim(),
                                company: companyController.text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : companyController.text.trim(),
                                note: noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                              );
                            });

                            if (context.mounted) {
                              Navigator.pop<bool>(sheetContext, true);
                            }
                          } catch (e) {
                            _showSnack('Error: $e');
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == true) {
      // kalau mau kirim sinyal ke halaman sebelumnya, Navigator.pop di CustomersPage
    }
  }

  Future<void> _confirmDelete() async {
    widget.onUserActivity();

    final theme = Theme.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Hapus Pelanggan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Yakin menghapus ${_customer.name}?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop<bool>(dialogContext, false),
              child: Text(
                'Batal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop<bool>(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      try {
        await _customerService.deleteCustomer(_customer.id);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showSnack('Gagal menghapus: $e');
      }
    }
  }

  // ======= UI =======

  @override
  Widget build(BuildContext context) {
    widget.onUserActivity();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final initials = _customer.name.isNotEmpty
        ? _customer.name.trim()[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        title: Text(
          'Detail Pelanggan',
          style: theme.textTheme.titleMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              // HEADER + CARD BESAR
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 50),
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDark ? 0.6 : 0.08,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          _customer.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _customer.email ?? 'Tidak ada email',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if ((_customer.phone ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _customer.phone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // CARD RINGKASAN TOTAL
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surfaceVariant
                                : theme.colorScheme.surfaceVariant
                                    .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _summaryItem(
                                label: 'Total Belanja',
                                value:
                                    _priceFormatter.format(_totalBelanja),
                                icon: Icons.trending_up_rounded,
                                iconColor: Colors.greenAccent,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: theme.dividerColor
                                    .withOpacity(isDark ? 0.4 : 0.3),
                              ),
                              _summaryItem(
                                label: 'Total Utang',
                                value: _priceFormatter.format(_totalUtang),
                                icon: Icons.trending_down_rounded,
                                iconColor: Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // AKSI CEPAT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _quickAction(
                              icon: Icons.edit,
                              label: 'Edit Data',
                              onTap: _openEditForm,
                            ),
                            _quickAction(
                              icon: Icons.history,
                              label: 'Riwayat',
                              onTap: () {
                                // scroll manual saja
                              },
                            ),
                            _quickAction(
                              icon: Icons.delete_outline,
                              label: 'Hapus',
                              onTap: _confirmDelete,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Informasi',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: onSurface.withOpacity(0.9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _infoTile(
                          title: 'Alamat',
                          value: _customer.address ?? 'Belum diisi',
                          icon: Icons.location_on_outlined,
                        ),
                        _infoTile(
                          title: 'Instansi / Perusahaan',
                          value: _customer.company ?? 'Belum diisi',
                          icon: Icons.domain_outlined,
                        ),
                        _infoTile(
                          title: 'Catatan',
                          value: _customer.note ?? 'Belum ada catatan',
                          icon: Icons.sticky_note_2_outlined,
                        ),
                      ],
                    ),
                  ),

                  // avatar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // RIWAYAT TRANSAKSI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Transaksi',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  Text(
                    '$_jumlahTransaksi transaksi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _isLoadingSales
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : _sales.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Belum ada transaksi untuk pelanggan ini.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              color: onSurface.withOpacity(0.7),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _sales.length,
                          itemBuilder: (context, index) {
                            final sale = _sales[index];
                            final isUtang = sale.status == 'kasbon';
                            final sisaUtang = isUtang
                                ? (sale.totalAmount - sale.paidAmount)
                                : 0;

                            final Color chipBg = isUtang
                                ? const Color(0xFFFFF3E0)
                                : const Color(0xFFE8F5E9);
                            final Color chipText = isUtang
                                ? const Color(0xFFF57C00)
                                : const Color(0xFF2E7D32);
                            final IconData statusIcon = isUtang
                                ? Icons.schedule_outlined
                                : Icons.check_circle_rounded;
                            final Color statusIconBg = isUtang
                                ? const Color(0xFFFFCC80)
                                : const Color(0xFFA5D6A7);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.35 : 0.06,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: isUtang
                                            ? [
                                                const Color(0xFFFFA726),
                                                const Color(0xFFF57C00),
                                              ]
                                            : [
                                                _primaryBlue,
                                                const Color(0xFF1565C0),
                                              ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(18),
                                        bottomLeft: Radius.circular(18),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: statusIconBg,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  statusIcon,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          _priceFormatter
                                                              .format(sale
                                                                  .totalAmount),
                                                          style: theme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: onSurface,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 10,
                                                            vertical: 3,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: chipBg,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                statusIcon,
                                                                size: 14,
                                                                color:
                                                                    chipText,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                isUtang
                                                                    ? 'Utang'
                                                                    : 'Lunas',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      chipText,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _dateFormatter.format(
                                                          sale.createdAt),
                                                      style: theme.textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                        fontSize: 11,
                                                        color: onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Dibayar: ${_priceFormatter.format(sale.paidAmount)}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 11,
                                              color: onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                          if (isUtang && sisaUtang > 0)
                                            Text(
                                              'Sisa utang: ${_priceFormatter.format(sisaUtang)}',
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 11,
                                                color:
                                                    const Color(0xFFFF7043),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== WIDGET KECIL =====

  Widget _summaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withOpacity(isDark ? 0.4 : 0.3),
        ),
        color: isDark
            ? theme.colorScheme.surfaceVariant
            : theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: onSurface,
        ),
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  size: 18,
                  color: theme.colorScheme.primary,
                )
              : null,
          labelText: label,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontSize: 12,
            color: onSurface.withOpacity(0.6),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: onSurface.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
