import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sale.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/sale_service.dart';

class CustomersPage extends StatefulWidget {
  final VoidCallback onUserActivity;

  const CustomersPage({super.key, required this.onUserActivity});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final CustomerService _customerService = CustomerService();
  final SaleService _saleService = SaleService();
  final NumberFormat _priceFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = false;
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _customerService.getCustomers();
      setState(() {
        _customers = data;
      });
    } catch (e) {
      _showSnack('Gagal memuat pelanggan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

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

  void _openHistory(Customer customer) async {
    widget.onUserActivity();

    final sales = await _saleService.getSales();
    final customerSales = sales
        .where((s) =>
            (s.customerName ?? '').toLowerCase() ==
            customer.name.toLowerCase())
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
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
                    'Riwayat ${customer.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: customerSales.isEmpty
                        ? const Center(
                            child: Text(
                                'Belum ada transaksi untuk pelanggan ini'),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: customerSales.length,
                            itemBuilder: (context, index) {
                              final Sale sale = customerSales[index];
                              String dateStr = '';
                              try {
                                dateStr = DateFormat(
                                  'dd MMM yyyy • HH:mm',
                                  'id_ID',
                                ).format(sale.createdAt);
                              } catch (_) {}

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  _priceFormatter.format(sale.totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '$dateStr\nStatus: ${sale.status == 'paid' ? 'Lunas' : 'Kasbon'}',
                                ),
                                isThreeLine: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: RefreshIndicator(
        onRefresh: _loadCustomers,
        child: _customers.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Belum ada pelanggan')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final c = _customers[index];

                  final pastelColors = [
                    const Color(0xFFFFF3E0), // soft orange
                    const Color(0xFFE3F2FD), // soft blue
                    const Color(0xFFFCE4EC), // soft pink
                    const Color(0xFFE8F5E9), // soft green
                    const Color(0xFFEDE7F6), // soft purple
                  ];
                  final bgColor =
                      pastelColors[index % pastelColors.length];

                  final initials = c.name.isNotEmpty
                      ? c.name.trim()[0].toUpperCase()
                      : '?';

                  String subtitle = '';
                  if (c.phone != null && c.phone!.isNotEmpty) {
                    subtitle = c.phone!;
                  } else if (c.email != null && c.email!.isNotEmpty) {
                    subtitle = c.email!;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openHistory(c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  Colors.white.withOpacity(0.9),
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (subtitle.isNotEmpty)
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  if (c.note != null &&
                                      c.note!.trim().isNotEmpty)
                                    Text(
                                      c.note!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 20,
                                  ),
                                  onPressed: () => _openForm(customer: c),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(c),
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
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
