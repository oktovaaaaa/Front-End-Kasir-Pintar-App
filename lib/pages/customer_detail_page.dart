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

  late Customer _customer; // agar bisa di-update setelah edit

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

      // filter berdasarkan nama customer
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

    final nameController = TextEditingController(text: _customer.name);
    final emailController = TextEditingController(text: _customer.email ?? '');
    final phoneController = TextEditingController(text: _customer.phone ?? '');
    final addressController =
        TextEditingController(text: _customer.address ?? '');
    final companyController =
        TextEditingController(text: _customer.company ?? '');
    final noteController = TextEditingController(text: _customer.note ?? '');

    final formKey = GlobalKey<FormState>();

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FF),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: _primaryBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: _primaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Edit Pelanggan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Perbarui informasi pelanggan agar data kasir selalu rapi dan terbaru.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8C8CA1),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Nama
                      _editField(
                        label: 'Nama lengkap',
                        controller: nameController,
                        icon: Icons.badge_outlined,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      // Telepon
                      _editField(
                        label: 'No. Telepon',
                        controller: phoneController,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      // Email
                      _editField(
                        label: 'Email (opsional)',
                        controller: emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      // Alamat
                      _editField(
                        label: 'Alamat (opsional)',
                        controller: addressController,
                        icon: Icons.location_on_outlined,
                      ),
                      // Instansi / perusahaan
                      _editField(
                        label: 'Instansi/Perusahaan (opsional)',
                        controller: companyController,
                        icon: Icons.apartment_outlined,
                      ),
                      // Catatan
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
                            onPressed: () => Navigator.pop<bool>(context, false),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              backgroundColor: _primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 18,
                            ),
                           label: const Text(
  'Simpan',
  style: TextStyle(
    fontWeight: FontWeight.w600,
    color: Colors.white, // ← ini bikin teks jadi putih
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
                                  address: addressController.text.trim().isEmpty
                                      ? null
                                      : addressController.text.trim(),
                                  company: companyController.text.trim().isEmpty
                                      ? null
                                      : companyController.text.trim(),
                                  note: noteController.text.trim().isEmpty
                                      ? null
                                      : noteController.text.trim(),
                                );

                                // update data di UI
                                setState(() {
                                  _customer = _customer.copyWith(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim().isEmpty
                                        ? null
                                        : emailController.text.trim(),
                                    phone: phoneController.text.trim().isEmpty
                                        ? null
                                        : phoneController.text.trim(),
                                    address:
                                        addressController.text.trim().isEmpty
                                            ? null
                                            : addressController.text.trim(),
                                    company:
                                        companyController.text.trim().isEmpty
                                            ? null
                                            : companyController.text.trim(),
                                    note: noteController.text.trim().isEmpty
                                        ? null
                                        : noteController.text.trim(),
                                  );
                                });

                                if (context.mounted) {
                                  Navigator.pop<bool>(context, true);
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
            ),
          ),
        );
      },
    );

    if (result == true) {
      // kalau mau kirim sinyal ke halaman sebelumnya bisa pakai Navigator.pop(result)
    }
  }

  Future<void> _confirmDelete() async {
    widget.onUserActivity();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Hapus Pelanggan'),
          content: Text('Yakin menghapus ${_customer.name}?'),
          actions: [
TextButton(
  onPressed: () => Navigator.pop<bool>(context, false),
  child: const Text(
    'Batal',
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
    ),
  ),
),

            ElevatedButton(
              onPressed: () => Navigator.pop<bool>(context, true),
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
          Navigator.pop(context, true); // balik ke list dan refresh di sana
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

    final initials = _customer.name.isNotEmpty
        ? _customer.name.trim()[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: _primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detail Pelanggan',
          style: TextStyle(color: Colors.white),
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
                  // background putih besar
                  Container(
                    margin: const EdgeInsets.only(top: 50),
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _customer.email ?? 'Tidak ada email',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if ((_customer.phone ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _customer.phone!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // CARD RINGKASAN TOTAL
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _summaryItem(
                                label: 'Total Belanja',
                                value: _priceFormatter.format(_totalBelanja),
                                icon: Icons.arrow_upward,
                                iconColor: Colors.green,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              _summaryItem(
                                label: 'Total Utang',
                                value: _priceFormatter.format(_totalUtang),
                                icon: Icons.arrow_downward,
                                iconColor: Colors.redAccent,
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
                                // hanya scroll ke bawah
                                // (user bisa lihat daftar transaksi di bawah)
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

                        // GENERAL INFO LIST (alamat, instansi, catatan)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Informasi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
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

                  // avatar bulat di atas card
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: _primaryBlue,
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
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$_jumlahTransaksi transaksi',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _isLoadingSales
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _sales.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Belum ada transaksi untuk pelanggan ini.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
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

                            final Color chipBg =
                                isUtang ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9);
                            final Color chipText =
                                isUtang ? const Color(0xFFF57C00) : const Color(0xFF2E7D32);
                            final IconData statusIcon =
                                isUtang ? Icons.schedule_outlined : Icons.check_circle_rounded;
                            final Color statusIconBg =
                                isUtang ? const Color(0xFFFFCC80) : const Color(0xFFA5D6A7);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  // strip warna kiri
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
                                      padding: const EdgeInsets.symmetric(
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
                                                              .format(sale.totalAmount),
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                                                color: chipText,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                isUtang
                                                                    ? 'Utang'
                                                                    : 'Lunas',
                                                                style: TextStyle(
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
                                                      _dateFormatter
                                                          .format(sale.createdAt),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey,
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
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (isUtang && sisaUtang > 0)
                                            Text(
                                              'Sisa utang: ${_priceFormatter.format(sisaUtang)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFD84315),
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
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 20,
              color: _primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
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
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Field builder khusus untuk dialog edit (underline + icon + label kecil)
  Widget _editField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  size: 18,
                  color: _primaryBlue,
                )
              : null,
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8C8CA1),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFFDDDDFF),
              width: 1,
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: _primaryBlue,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
