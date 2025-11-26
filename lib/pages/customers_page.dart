import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/sale.dart';
import '../services/customer_service.dart';
import '../services/sale_service.dart';
import 'customer_detail_page.dart';

class CustomersPage extends StatefulWidget {
  final VoidCallback onUserActivity;

  const CustomersPage({super.key, required this.onUserActivity});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final CustomerService _customerService = CustomerService();
  final SaleService _saleService = SaleService();

  static const Color _primaryBlue = Color(0xFF57A0D3);

  final NumberFormat _priceFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = false;
  List<Customer> _customers = [];

  /// total sisa utang per nama customer
  Map<String, double> _utangPerCustomer = {};

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _customerService.getCustomers(),
        _saleService.getSales(),
      ]);

      final customers = results[0] as List<Customer>;
      final sales = results[1] as List<Sale>;

      final Map<String, double> utangMap = {};
      for (final s in sales) {
        if (s.status == 'kasbon' && s.customerName != null) {
          final sisa = s.totalAmount - s.paidAmount;
          if (sisa > 0) {
            final key = s.customerName!.toLowerCase();
            utangMap[key] = (utangMap[key] ?? 0) + sisa;
          }
        }
      }

      setState(() {
        _customers = customers;
        _utangPerCustomer = utangMap;
      });
    } catch (e) {
      _showSnack('Gagal memuat pelanggan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalUtangAll =>
      _utangPerCustomer.values.fold(0.0, (p, v) => p + v);

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ============ FORM TAMBAH / EDIT ============

  Future<void> _openForm({Customer? customer}) async {
    widget.onUserActivity();

    final nameController = TextEditingController(text: customer?.name ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController =
        TextEditingController(text: customer?.address ?? '');
    final companyController =
        TextEditingController(text: customer?.company ?? '');
    final noteController = TextEditingController(text: customer?.note ?? '');

    final formKey = GlobalKey<FormState>();
    final isEdit = customer != null;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nama lengkap'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration:
                        const InputDecoration(labelText: 'No. Telepon'),
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration:
                        const InputDecoration(labelText: 'Email (opsional)'),
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration:
                        const InputDecoration(labelText: 'Alamat (opsional)'),
                  ),
                  TextFormField(
                    controller: companyController,
                    decoration: const InputDecoration(
                        labelText: 'Instansi/Perusahaan (opsional)'),
                  ),
                  TextFormField(
                    controller: noteController,
                    decoration:
                        const InputDecoration(labelText: 'Catatan (opsional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop<bool>(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  if (isEdit) {
                    await _customerService.updateCustomer(
                      id: customer!.id,
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
                  } else {
                    await _customerService.createCustomer(
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
                  }

                  if (context.mounted) Navigator.pop<bool>(context, true);
                } catch (e) {
                  _showSnack('Error: $e');
                }
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _loadCustomers();
    }
  }

  Future<void> _confirmDelete(Customer customer) async {
    widget.onUserActivity();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Hapus Pelanggan'),
          content: Text('Yakin menghapus ${customer.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop<bool>(context, false),
              child: const Text('Batal'),
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
        await _customerService.deleteCustomer(customer.id);
        _loadCustomers();
      } catch (e) {
        _showSnack('Gagal menghapus: $e');
      }
    }
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      body: RefreshIndicator(
        onRefresh: _loadCustomers,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: _customers.isEmpty ? 1 : _customers.length + 1,
          itemBuilder: (context, index) {
            // index 0 = header seperti contoh UI
            if (index == 0) {
              return _buildHeader();
            }

            if (_customers.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: Text('Belum ada pelanggan')),
              );
            }

            final c = _customers[index - 1];
            final initials = c.name.isNotEmpty
                ? c.name.trim()[0].toUpperCase()
                : '?';

            final key = c.name.toLowerCase();
            final sisaUtang = _utangPerCustomer[key] ?? 0;

            String subtitle = '';
            if (c.phone != null && c.phone!.isNotEmpty) {
              subtitle = c.phone!;
            } else if (c.email != null && c.email!.isNotEmpty) {
              subtitle = c.email!;
            }

            return GestureDetector(
              onTap: () async {
                widget.onUserActivity();
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailPage(
                      customer: c,
                      onUserActivity: widget.onUserActivity,
                    ),
                  ),
                );
                if (changed == true) {
                  _loadCustomers();
                }
              },
              onLongPress: () => _confirmDelete(c),
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // icon / avatar kiri
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // teks tengah
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            if (c.note != null && c.note!.trim().isNotEmpty)
                              Text(
                                c.note!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // amount / status kanan
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (sisaUtang > 0)
                            Text(
                              _priceFormatter.format(sisaUtang),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD84315),
                              ),
                            )
                          else
                            const Text(
                              'Lunas',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            sisaUtang > 0 ? 'Sisa utang' : 'Tidak ada utang',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 18,
                            ),
                            onPressed: () {
                              _showCustomerMenu(c);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryBlue,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Header ala “card + summary” seperti gambar
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pelanggan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kelola data pelanggan dan utang mereka.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        // kartu ringkasan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Utang Pelanggan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _priceFormatter.format(_totalUtangAll),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _headerStat(
                    label: 'Jumlah pelanggan',
                    value: _customers.length.toString(),
                  ),
                  const SizedBox(width: 16),
                  _headerStat(
                    label: 'Pelanggan berutang',
                    value: _utangPerCustomer.length.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        const Text(
          'Daftar Pelanggan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _headerStat({required String label, required String value}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerMenu(Customer c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit pelanggan'),
                onTap: () {
                  Navigator.pop(context);
                  _openForm(customer: c);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(c);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
