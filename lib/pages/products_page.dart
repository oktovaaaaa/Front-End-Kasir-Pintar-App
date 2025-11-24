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
      _loadInitialData();
    }
  }
  /// ====== END FUNGSI BOTTOM SHEET ======

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
                          trailing: SizedBox(
                            height: 72,
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _openProductForm(product: p),
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
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
