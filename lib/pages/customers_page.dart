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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
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
                    controller: emailController,
                    decoration:
                        const InputDecoration(labelText: 'Email (opsional)'),
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration:
                        const InputDecoration(labelText: 'No. Telepon'),
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

    // sementara: panggil sales list dan filter di sisi client berdasarkan nama snapshot
    // nanti bisa diganti pakai endpoint /customers/{id} kalau mau lebih detail

    final sales = await _saleService.getSales(); // kita sudah punya ini
    final customerSales = sales
        .where((s) => (s.customerName ?? '').toLowerCase() ==
            customer.name.toLowerCase())
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                'Riwayat ${customer.name}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: customerSales.isEmpty
                    ? const Center(
                        child: Text('Belum ada transaksi untuk pelanggan ini'),
                      )
                    : ListView.builder(
                        itemCount: customerSales.length,
                        itemBuilder: (context, index) {
                          final sale = customerSales[index];
                          return ListTile(
                            title: Text(
                              _priceFormatter.format(sale.totalAmount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                'Status: ${sale.status == 'paid' ? 'Lunas' : 'Kasbon'}'),
                          );
                        },
                      ),
              ),
            ],
          ),
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
                padding: const EdgeInsets.all(12),
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final c = _customers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _openHistory(c),
                      title: Text(c.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.phone != null && c.phone!.isNotEmpty)
                            Text(c.phone!),
                          if (c.email != null && c.email!.isNotEmpty)
                            Text(
                              c.email!,
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openForm(customer: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(c),
                          ),
                        ],
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
