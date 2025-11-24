class Product {
  final int id;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final int price;       // harga jual (dalam rupiah, tanpa koma)
  final int costPrice;   // harga modal
  final int stock;
  final String? description;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.description,
    this.imageUrl,
  });

  // helper untuk parse angka dari JSON (bisa "12500.00", 12500, 12500.0)
  static int _parseInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.round();

    final s = value.toString();

    // pertama coba parse sebagai double dulu (buat kasus "12500.00")
    final d = double.tryParse(s);
    if (d != null) return d.round();

    // fallback terakhir: coba parse int biasa
    return int.tryParse(s) ?? 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      categoryId: json['category_id'] == null
          ? null
          : int.tryParse(json['category_id'].toString()),
      categoryName: json['category']?['name']?.toString(),
      price: _parseInt(json['price']),
      costPrice: _parseInt(json['cost_price']),
      stock: _parseInt(json['stock']),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['image_path']?.toString(),
    );
  }
}
