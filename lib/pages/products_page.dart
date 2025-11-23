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

  bool _isLoading = false;
  List<Product> _products = [];
  List<Category> _categories = [];

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

      setState(() {
        _products = results[0] as List<Product>;
        _categories = results[1] as List<Category>;
      });
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showProductForm({Product? product}) async {
    widget.onUserActivity();

    final isEdit = product != null;

    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
        text: product != null ? product.price.toStringAsFixed(0) : '');
    final stockController = TextEditingController(
        text: product != null ? product.stock.toString() : '');
    final descriptionController =
        TextEditingController(text: product?.description ?? '');

    int? selectedCategoryId = product?.categoryId;
    File? pickedImageFile;

    final formKey = GlobalKey<FormState>();
    final picker = ImagePicker();

    // fungsi untuk tambah kategori baru dari dalam dialog produk
    Future<void> _handleAddCategory(StateSetter setStateDialog) async {
      final catNameController = TextEditingController();
      final catDescController = TextEditingController();
      final catFormKey = GlobalKey<FormState>();

      final Category? newCategory = await showDialog<Category?>(
        context: context,
        builder: (context) {
          return AlertDialog(
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
        // update list kategori di halaman
        setState(() {
          _categories.add(newCategory);
        });
        // pilih kategori baru di dialog produk
        setStateDialog(() {
          selectedCategoryId = newCategory.id;
        });
      }
    }

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // FOTO
                      GestureDetector(
                        onTap: () async {
                          final XFile? picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              pickedImageFile = File(picked.path);
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
                                child: pickedImageFile != null
                                    ? Image.file(
                                        pickedImageFile!,
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
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),

                      // DROPDOWN KATEGORI + TAMBAH KATEGORI BARU
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
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
                        onChanged: (value) async {
                          if (value == -1) {
                            await _handleAddCategory(setStateDialog);
                          } else {
                            setStateDialog(() {
                              selectedCategoryId = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga (contoh: 12500)',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Harga wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Stok wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan (opsional)',
                        ),
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
                      final name = nameController.text.trim();
                      final price = double.parse(
                        priceController.text.replaceAll('.', '').trim(),
                      );
                      final stock = int.parse(stockController.text.trim());

                      if (isEdit) {
                        await _productService.updateProduct(
                          id: product!.id,
                          name: name,
                          stock: stock,
                          price: price,
                          categoryId: selectedCategoryId,
                          description:
                              descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                          imageFile: pickedImageFile,
                        );
                      } else {
                        await _productService.createProduct(
                          name: name,
                          stock: stock,
                          price: price,
                          categoryId: selectedCategoryId,
                          description:
                              descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                          imageFile: pickedImageFile,
                        );
                      }

                      if (mounted) Navigator.pop<bool>(context, true);
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
      },
    );

    if (result == true) {
      _loadInitialData();
    }
  }

  Future<void> _confirmDelete(Product product) async {
    widget.onUserActivity();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        _loadInitialData();
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
            : _products.isEmpty
                ? const Center(child: Text('Belum ada produk'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: p.imageUrl != null
                                  ? Image.network(
                                      p.imageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(p.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _priceFormatter.format(p.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Stok: ${p.stock}'),
                              if (p.categoryName != null)
                                Text('Kategori: ${p.categoryName}'),
                              if (p.description != null &&
                                  p.description!.isNotEmpty)
                                Text(
                                  p.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showProductForm(product: p),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(p),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
