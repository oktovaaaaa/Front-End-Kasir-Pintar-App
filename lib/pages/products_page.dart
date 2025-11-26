import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';

class ProductsPage extends StatefulWidget {
  final VoidCallback onUserActivity;

  const ProductsPage({super.key, required this.onUserActivity});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final NumberFormat _priceFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const Color _primaryBlue = Color(0xFF57A0D3);

  bool _isLoading = false;
  List<Product> _products = [];
  List<Category> _categories = [];

  // state untuk search & filter
  String _searchText = '';
  int? _selectedCategoryId;
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _productService.getProducts(),
        _categoryService.getCategories(),
      ]);

      _products = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
      _applyFilter();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchText.toLowerCase();

    setState(() {
      _filteredProducts = _products.where((p) {
        final matchSearch = query.isEmpty
            ? true
            : p.name.toLowerCase().contains(query) ||
                (p.categoryName?.toLowerCase().contains(query) ?? false);
        final matchCategory = _selectedCategoryId == null
            ? true
            : p.categoryId == _selectedCategoryId;
        return matchSearch && matchCategory;
      }).toList();
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// ====== BOTTOM SHEET DETAIL PRODUK ======
  Future<void> _openProductDetail(Product product) async {
    widget.onUserActivity();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: product.imageUrl != null
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (product.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryBlue.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 14,
                                    color: _primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.categoryName!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow(
                  icon: Icons.sell_outlined,
                  label: 'Harga Jual',
                  value: _priceFormatter.format(product.price),
                  valueColor: Colors.blue[700],
                ),
                const SizedBox(height: 10),
                _detailRow(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Harga Modal',
                  value: _priceFormatter.format(product.costPrice),
                  valueColor: Colors.grey[800],
                ),
                const SizedBox(height: 10),
                _detailRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stok',
                  value: '${product.stock} pcs',
                  valueColor: Colors.orange[700],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Keterangan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    (product.description == null ||
                            product.description!.trim().isEmpty)
                        ? 'Tidak ada keterangan.'
                        : product.description!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: _primaryBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  /// ====== BOTTOM SHEET FORM PRODUK ======
  Future<void> _openProductForm({Product? product}) async {
    widget.onUserActivity();

    final isEdit = product != null;

    final nameController = TextEditingController(text: product?.name ?? '');
    final costPriceController = TextEditingController(
        text: product != null ? product.costPrice.toString() : '');
    final priceController = TextEditingController(
        text: product != null ? product.price.toString() : '');
    final stockController = TextEditingController(
        text: product != null ? product.stock.toString() : '');
    final descController =
        TextEditingController(text: product?.description ?? '');

    int? selectedCategoryId = product?.categoryId;
    File? pickedImage;

    final formKey = GlobalKey<FormState>();
    final picker = ImagePicker();

    // fungsi untuk tambah kategori baru dari dalam bottom sheet
    Future<void> _handleAddCategory(StateSetter setStateSheet) async {
      final catNameController = TextEditingController();
      final catDescController = TextEditingController();
      final catFormKey = GlobalKey<FormState>();

      final Category? newCategory = await showDialog<Category?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('Tambah Kategori'),
            content: SingleChildScrollView(
              child: Form(
                key: catFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: catNameController,
                      decoration:
                          const InputDecoration(labelText: 'Nama kategori'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Nama kategori wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: catDescController,
                      decoration: const InputDecoration(
                          labelText: 'Deskripsi (opsional)'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop<Category?>(context, null),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!catFormKey.currentState!.validate()) return;

                  try {
                    final created = await _categoryService.createCategory(
                      name: catNameController.text.trim(),
                      description: catDescController.text.trim().isEmpty
                          ? null
                          : catDescController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pop<Category?>(context, created);
                    }
                  } catch (e) {
                    _showSnack('Error: $e');
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );

      if (newCategory != null) {
        if (mounted) {
          setState(() {
            _categories.add(newCategory);
          });
        }
        setStateSheet(() {
          selectedCategoryId = newCategory.id;
        });
      }
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          isEdit ? 'Edit Produk' : 'Tambah Produk',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ==== PILIH FOTO ====
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final XFile? picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              setStateSheet(() {
                                pickedImage = File(picked.path);
                              });
                            }
                          },
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: pickedImage != null
                                      ? Image.file(
                                          pickedImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : (product?.imageUrl != null
                                          ? Image.network(
                                              product!.imageUrl!,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.camera_alt,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            )),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap untuk pilih foto',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration:
                            const InputDecoration(labelText: 'Kategori'),
                        items: [
                          ..._categories.map(
                            (c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                          const DropdownMenuItem<int>(
                            value: -1,
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 18),
                                SizedBox(width: 4),
                                Text('Tambah kategori baru'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) async {
                          if (val == -1) {
                            await _handleAddCategory(setStateSheet);
                          } else {
                            setStateSheet(() {
                              selectedCategoryId = val;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: costPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Modal (contoh: 10000)',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Harga modal wajib diisi';
                          }
                          if (int.tryParse(v) == null) {
                            return 'Masukkan angka saja';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual (contoh: 12500)',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Harga jual wajib diisi';
                          }
                          final p = int.tryParse(v);
                          final c = int.tryParse(costPriceController.text);
                          if (p == null) return 'Masukkan angka saja';
                          if (c != null && p < c) {
                            return 'Harga jual harus ≥ harga modal';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Stok wajib diisi';
                          }
                          if (int.tryParse(v) == null) {
                            return 'Masukkan angka saja';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan (opsional)',
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final name = nameController.text.trim();
                              final costPrice =
                                  int.parse(costPriceController.text.trim());
                              final price =
                                  int.parse(priceController.text.trim());
                              final stock =
                                  int.parse(stockController.text.trim());
                              final desc = descController.text.trim();

                              try {
                                if (isEdit) {
                                  await _productService.updateProduct(
                                    id: product!.id,
                                    name: name,
                                    price: price,
                                    costPrice: costPrice,
                                    stock: stock,
                                    categoryId: selectedCategoryId,
                                    description:
                                        desc.isEmpty ? null : desc,
                                    imageFile: pickedImage,
                                  );
                                } else {
                                  await _productService.createProduct(
                                    name: name,
                                    price: price,
                                    costPrice: costPrice,
                                    stock: stock,
                                    categoryId: selectedCategoryId,
                                    description:
                                        desc.isEmpty ? null : desc,
                                    imageFile: pickedImage,
                                  );
                                }

                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            child: Text(isEdit ? 'Simpan' : 'Tambah'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      await _loadInitialData();
    }
  }

  /// ====== END FUNGSI BOTTOM SHEET ======

  Future<void> _confirmDelete(Product product) async {
    widget.onUserActivity();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Hapus Produk'),
          content: Text('Yakin menghapus "${product.name}" ?'),
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
        await _productService.deleteProduct(product.id);
        await _loadInitialData();
      } catch (e) {
        _showSnack('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(),
        backgroundColor: _primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    if (_products.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Belum ada produk')),
        ],
      );
    }

    final list = _filteredProducts.isEmpty ? _products : _filteredProducts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        const SizedBox(height: 4),
        // _buildHeader(),
        const SizedBox(height: 16),
        _buildSearchAndFilter(),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final p = list[index];
            return _buildProductCard(p);
          },
        ),
      ],
    );
  }

  // Widget _buildHeader() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       const Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Produk & Stok',
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           SizedBox(height: 4),
  //           Text(
  //             'Kelola produk yang dijual di toko',
  //             style: TextStyle(
  //               fontSize: 12,
  //               color: Colors.grey,
  //             ),
  //           ),
  //         ],
  //       ),
  //       Container(
  //         padding: const EdgeInsets.all(8),
  //         decoration: BoxDecoration(
  //           color: _primaryBlue.withOpacity(0.1),
  //           shape: BoxShape.circle,
  //         ),
  //         child: Icon(
  //           Icons.inventory_2_outlined,
  //           color: _primaryBlue,
  //         ),
  //       )
  //     ],
  //   );
  // }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        // Search
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Cari produk atau kategori...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              widget.onUserActivity();
              _searchText = value;
              _applyFilter();
            },
          ),
        ),
        const SizedBox(height: 10),
        // Filter kategori
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedCategoryId,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                ),
                onChanged: (value) {
                  widget.onUserActivity();
                  setState(() {
                    _selectedCategoryId = value;
                  });
                  _applyFilter();
                },
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Semua kategori'),
                  ),
                  ..._categories.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product p) {
    return GestureDetector(
      onTap: () => _openProductDetail(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon + action
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: _primaryBlue,
                  ),
                ),
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.edit,
                        size: 20,
                      ),
                      onPressed: () => _openProductForm(product: p),
                    ),
                    const SizedBox(height: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmDelete(p),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (p.categoryName != null)
              Text(
                p.categoryName!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            const Spacer(),
            Text(
              _priceFormatter.format(p.price),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modal: ${_priceFormatter.format(p.costPrice)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${p.stock} stok',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
