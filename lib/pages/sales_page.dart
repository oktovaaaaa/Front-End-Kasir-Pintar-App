import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';
import '../services/category_service.dart';
import '../services/customer_service.dart';

class SalesPage extends StatefulWidget {
  final VoidCallback onUserActivity;

  const SalesPage({super.key, required this.onUserActivity});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final ProductService _productService = ProductService();
  final SaleService _saleService = SaleService();
  final CategoryService _categoryService = CategoryService();
  final CustomerService _customerService = CustomerService();

  final NumberFormat _priceFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const Color _primaryBlue = Color(0xFF57A0D3);

  bool _isLoading = false;

  // ====== DATA PRODUK & KATEGORI ======
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];

  int? _selectedCategoryId; // null = semua kategori
  String _searchText = '';

  // ====== DATA PELANGGAN ======
  List<Customer> _customers = [];
  Customer? _selectedCustomer;

  /// cart: key = productId, value = qty
  final Map<int, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _productService.getProducts(),
        _categoryService.getCategories(),
        _customerService.getCustomers(),
      ]);

      _allProducts = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
      _customers = results[2] as List<Customer>;
      _selectedCustomer = null;

      _applyFilter();
    } catch (e) {
      _showSnack('Gagal memuat data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final lowerSearch = _searchText.toLowerCase();

    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchCategory = _selectedCategoryId == null
            ? true
            : p.categoryId == _selectedCategoryId;

        final matchSearch = _searchText.isEmpty
            ? true
            : p.name.toLowerCase().contains(lowerSearch);

        return matchCategory && matchSearch;
      }).toList();
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // cari product dari id
  Product? _findProductById(int id) {                // NEW
    try {
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _addToCart(Product product) {
    widget.onUserActivity();

    // CEK STOK sebelum tambah                              // NEW
    final currentQty = _cart[product.id] ?? 0;
    if (currentQty >= product.stock) {
      _showSnack('Stok ${product.name} sudah habis / maksimal.');
      return;
    }

    setState(() {
      _cart.update(product.id, (old) => old + 1, ifAbsent: () => 1);
    });
  }

  void _removeFromCart(Product product) {
    widget.onUserActivity();
    if (!_cart.containsKey(product.id)) return;

    setState(() {
      final current = _cart[product.id]!;
      if (current <= 1) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = current - 1;
      }
    });
  }

  int _getQty(Product product) => _cart[product.id] ?? 0;

  int get _totalItems =>
      _cart.values.fold(0, (prev, qty) => prev + qty);

  double get _totalPrice {
    double total = 0;
    for (final entry in _cart.entries) {
      final matches =
          _allProducts.where((p) => p.id == entry.key).toList();
      if (matches.isNotEmpty) {
        final product = matches.first;
        total += product.price * entry.value;
      }
    }
    return total;
  }

  // ========= BOTTOM SHEET: DETAIL KERANJANG =========     // NEW
  void _openCartSheet() {
    widget.onUserActivity();
    if (_cart.isEmpty) {
      _showSnack('Keranjang masih kosong');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void refresh() {
              // update tampilan di sheet & halaman utama
              setSheetState(() {});
              setState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rincian Keranjang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_totalItems} item',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // LIST PRODUK DI KERANJANG
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: ListView(
                      children: _cart.entries.map((entry) {
                        final product = _findProductById(entry.key);
                        if (product == null) {
                          return const SizedBox.shrink();
                        }
                        final qty = entry.value;
                        final subtotal = product.price * qty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Info produk
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _priceFormatter
                                          .format(product.price),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stok: ${product.stock}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Control qty
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 22,
                                    ),
                                    color: _primaryBlue,
                                    onPressed: () {
                                      if (qty <= 1) {
                                        _cart.remove(product.id);
                                      } else {
                                        _cart[product.id] =
                                            qty - 1;
                                      }
                                      refresh();
                                    },
                                  ),
                                  Text(
                                    '$qty',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 22,
                                    ),
                                    color: qty >= product.stock
                                        ? Colors.grey
                                        : _primaryBlue,
                                    onPressed: qty >= product.stock
                                        ? null
                                        : () {
                                            final current =
                                                _cart[product.id] ??
                                                    0;
                                            if (current >=
                                                product.stock) {
                                              _showSnack(
                                                  'Stok ${product.name} sudah maksimal.');
                                              return;
                                            }
                                            _cart[product.id] =
                                                current + 1;
                                            refresh();
                                          },
                                  ),
                                ],
                              ),

                              const SizedBox(width: 8),

                              // subtotal
                              Text(
                                _priceFormatter.format(subtotal),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Divider(height: 24),

                  // TOTAL
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _priceFormatter.format(_totalPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // BUTTON LANJUT PEMBAYARAN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                      onPressed: _cart.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
                              _openPaymentSheet();
                            },
                      child: const Text(
                        'Lanjut ke Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // ========= BOTTOM SHEET: PEMBAYARAN =========
  void _openPaymentSheet() {
    widget.onUserActivity();
    if (_cart.isEmpty) {
      _showSnack('Pilih produk dulu');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final TextEditingController paidAmountController =
            TextEditingController();

        double kembalian = 0;
        double sisaBayar = 0; // NEW

        // gunakan selectedCustomer global sebagai default di picker
        Customer? selectedCustomer = _selectedCustomer;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void _updateAmounts() {                  // UPDATED
              final text = paidAmountController.text
                  .replaceAll('.', '')
                  .trim();
              final bayar = double.tryParse(text) ?? 0;

              setSheetState(() {
                final diff = bayar - _totalPrice;
                if (diff >= 0) {
                  // uang cukup / lebih
                  kembalian = diff;
                  sisaBayar = 0;
                } else {
                  // kasbon
                  kembalian = 0;
                  sisaBayar = -diff;
                }
              });
            }

            Future<void> _submit() async {
              final text = paidAmountController.text
                  .replaceAll('.', '')
                  .trim();
              final bayar = double.tryParse(text) ?? 0;

              final isKasbon = bayar < _totalPrice;

              // VALIDASI KASBON: harus pilih pelanggan
              if (isKasbon) {
                if (_customers.isEmpty) {
                  _showSnack(
                      'Untuk kasbon, buat pelanggan dulu di menu Pelanggan.');
                  return;
                }
                if (selectedCustomer == null) {
                  _showSnack(
                      'Untuk kasbon, pilih pelanggan terlebih dahulu.');
                  return;
                }
              }

              try {
                final res = await _saleService.createSale(
                  cart: _cart,
                  paidAmount: bayar,
                  customerId: selectedCustomer?.id,
                  customerName: selectedCustomer?.name,
                  paymentMethod: 'cash',
                );

                final status =
                    res['status']?.toString() ?? 'paid';

                Navigator.pop(context); // tutup bottom sheet
                setState(() {
                  _cart.clear();
                  _selectedCustomer = selectedCustomer;
                });

                if (status == 'kasbon') {
                  _showSnack(
                      'Transaksi tersimpan sebagai KASBON (utang pelanggan).');
                } else {
                  _showSnack(
                      'Transaksi LUNAS tersimpan di riwayat.');
                }
              } catch (e) {
                _showSnack('Gagal menyimpan transaksi: $e');
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Pembayaran',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // LIST PRODUK
                  SizedBox(
                    height: 180,
                    child: ListView(
                      children: _cart.entries.map((entry) {
                        final matches = _allProducts
                            .where((p) => p.id == entry.key)
                            .toList();
                        if (matches.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final product = matches.first;

                        final qty = entry.value;
                        final subtotal =
                            product.price * qty;
                        return ListTile(
                          dense: true,
                          contentPadding:
                              EdgeInsets.zero,
                          title: Text(product.name),
                          subtitle: Text(
                              '${qty}x  ${_priceFormatter.format(product.price)}'),
                          trailing: Text(
                            _priceFormatter
                                .format(subtotal),
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Divider(),

                  // TOTAL
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold),
                      ),
                      Text(
                        _priceFormatter
                            .format(_totalPrice),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // NAMA PELANGGAN PICKER
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nama Pelanggan (opsional)\n'
                      'Wajib dipilih kalau bayar kurang (kasbon).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple[400],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  DropdownButtonFormField<Customer?>(
                    value: selectedCustomer,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'Pilih pelanggan atau biarkan kosong kalau lunas',
                      border:
                          UnderlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<
                          Customer?>(
                        value: null,
                        child:
                            Text('Tanpa pelanggan'),
                      ),
                      ..._customers.map(
                        (c) =>
                            DropdownMenuItem<Customer?>(
                          value: c,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() {
                        selectedCustomer = value;
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  // UANG DITERIMA
                  TextField(
                    controller: paidAmountController,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Uang diterima (boleh 0 kalau full kasbon)',
                      hintText: 'contoh: 50000',
                    ),
                    onChanged: (_) => _updateAmounts(),
                  ),
                  const SizedBox(height: 8),

                  // KEMBALIAN + SISA BAYAR
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text('Kembalian'),
                      Text(
                        _priceFormatter.format(
                            kembalian),
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Sisa yang harus dibayar',
                      ),
                      Text(
                        _priceFormatter.format(
                            sisaBayar),
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color: sisaBayar > 0
                              ? Colors.red[400]
                              : Colors
                                  .grey[800],
                        ),
                      ),
                    ],
                  ),
                  if (sisaBayar > 0)
                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Padding(
                        padding:
                            const EdgeInsets
                                    .only(
                                top: 4.0),
                        child: Text(
                          'Sisa ini akan tercatat sebagai KASBON (utang pelanggan).',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.red[400],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // BUTTON SIMPAN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text(
                          'Simpan Transaksi'),
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
    return Scaffold(
      body: Container(
        // gradient lembut
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _primaryBlue.withOpacity(0.18),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator())
              : _allProducts.isEmpty
                  ? const Center(
                      child: Text(
                          'Belum ada produk'))
                  : Column(
                      children: [
                        const SizedBox(height: 8),

                        // ====== SEARCH + DROPDOWN KATEGORI ======
                        Padding(
                          padding:
                              const EdgeInsets
                                      .symmetric(
                                  horizontal: 16),
                          child: Row(
                            children: [
                              // SEARCH
                              Expanded(
                                child:
                                    Container(
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .white,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors
                                            .black
                                            .withOpacity(
                                                0.05),
                                        blurRadius:
                                            10,
                                        offset:
                                            const Offset(
                                                0,
                                                4),
                                      ),
                                    ],
                                  ),
                                  child:
                                      TextField(
                                    decoration:
                                        const InputDecoration(
                                      hintText:
                                          'Cari produk...',
                                      border:
                                          InputBorder
                                              .none,
                                      prefixIcon:
                                          Icon(Icons
                                              .search),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal:
                                              16,
                                          vertical:
                                              12),
                                    ),
                                    onChanged:
                                        (value) {
                                      _searchText =
                                          value;
                                      _applyFilter();
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  width: 10),

                              // DROPDOWN KATEGORI
                              Container(
                                padding:
                                    const EdgeInsets
                                            .symmetric(
                                        horizontal:
                                            12,
                                        vertical:
                                            8),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withOpacity(
                                              0.06),
                                      blurRadius:
                                          8,
                                      offset:
                                          const Offset(
                                              0,
                                              3),
                                    ),
                                  ],
                                ),
                                child:
                                    DropdownButtonHideUnderline(
                                  child:
                                      DropdownButton<
                                          int?>(
                                    value:
                                        _selectedCategoryId,
                                    icon:
                                        const Icon(
                                      Icons
                                          .keyboard_arrow_down_rounded,
                                      size: 18,
                                    ),
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          13,
                                      color: Colors
                                          .black,
                                    ),
                                    onChanged:
                                        (value) {
                                      _selectedCategoryId =
                                          value;
                                      _applyFilter();
                                    },
                                    items: [
                                      const DropdownMenuItem<
                                          int?>(
                                        value:
                                            null,
                                        child: Text(
                                            'Semua'),
                                      ),
                                      ..._categories
                                          .map(
                                        (c) =>
                                            DropdownMenuItem<
                                                int?>(
                                          value:
                                              c.id,
                                          child: Text(
                                              c.name),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                            height: 12),

                        // ====== GRID PRODUK ======
                        Expanded(
                          child:
                              Container(
                            decoration:
                                const BoxDecoration(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius
                                      .only(
                                topLeft: Radius
                                    .circular(
                                        24),
                                topRight: Radius
                                    .circular(
                                        24),
                              ),
                            ),
                            child:
                                GridView
                                    .builder(
                              padding:
                                  const EdgeInsets
                                          .fromLTRB(
                                      16,
                                      16,
                                      16,
                                      90),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    2,
                                mainAxisSpacing:
                                    12,
                                crossAxisSpacing:
                                    12,
                                childAspectRatio:
                                    0.78,
                              ),
                              itemCount:
                                  _filteredProducts
                                      .length,
                              itemBuilder:
                                  (context,
                                      index) {
                                final p =
                                    _filteredProducts[
                                        index];
                                final qty =
                                    _getQty(p);
                                return _buildProductCard(
                                    p, qty);
                              },
                            ),
                          ),
                        ),

                        // ====== BOTTOM CART PILL ======
                        _buildBottomCartBar(),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product p, int qty) {
    return GestureDetector(
      onTap: () => _addToCart(p),
      onLongPress: () => _removeFromCart(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // GAMBAR
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: SizedBox.expand(
                  child: p.imageUrl != null
                      ? Image.network(
                          p.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color:
                              Colors.grey[200],
                          child: const Icon(
                            Icons
                                .image_outlined,
                            size: 40,
                            color:
                                Colors.grey,
                          ),
                        ),
                ),
              ),
            ),

            // ISI
            Padding(
              padding: const EdgeInsets
                      .symmetric(
                  horizontal: 10,
                  vertical: 8),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // HARGA DALAM PILL BIRU
                  Container(
                    padding:
                        const EdgeInsets
                                .symmetric(
                            horizontal: 10,
                            vertical: 4),
                    decoration:
                        BoxDecoration(
                      color: _primaryBlue,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
                    ),
                    child: Text(
                      _priceFormatter
                          .format(p.price),
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 6),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                  const SizedBox(
                      height: 4),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        '${p.stock} Stok',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors
                              .grey[600],
                        ),
                      ),
                      if (qty > 0)
                        Container(
                          padding:
                              const EdgeInsets
                                      .symmetric(
                                  horizontal:
                                      8,
                                  vertical:
                                      2),
                          decoration:
                              BoxDecoration(
                            color: _primaryBlue
                                .withOpacity(
                                    0.15),
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        12),
                          ),
                          child: Text(
                            'x$qty',
                            style:
                                const TextStyle(
                              fontSize:
                                  11,
                              color:
                                  _primaryBlue,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCartBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
        child: GestureDetector(
          // DULUNYA _openPaymentSheet, SEKARANG DETAIL KERANJANG   // UPDATED
          onTap:
              _cart.isEmpty ? null : _openCartSheet,
          child: Opacity(
            opacity: _cart.isEmpty ? 0.4 : 1,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius:
                    BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue
                        .withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .shopping_bag_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Lihat keranjang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // badge item
                  Container(
                    padding:
                        const EdgeInsets
                                .symmetric(
                            horizontal: 8,
                            vertical: 4),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  12),
                    ),
                    child: Text(
                      '${_totalItems}x',
                      style:
                          const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            _primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _priceFormatter
                        .format(_totalPrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
