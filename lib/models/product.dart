class Product {
  final int id;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final int stock;
  final double price;
  final String? description;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    required this.stock,
    required this.price,
    this.description,
    this.imageUrl,
  });

  // BACA DARI API
  factory Product.fromJson(Map<String, dynamic> json) {
    // id bisa juga dikirim sebagai String, kita amankan
    final dynamic idRaw = json['id'];
    final int idParsed =
        idRaw == null ? 0 : int.tryParse(idRaw.toString()) ?? 0;

    // category_id dari backend kadang String → parse aman
    final dynamic catIdRaw = json['category_id'];
    final int? catIdParsed = catIdRaw == null
        ? null
        : int.tryParse(catIdRaw.toString());

    // price & stock juga kita parse aman
    final dynamic priceRaw = json['price'];
    final double priceParsed =
        priceRaw == null ? 0.0 : double.tryParse(priceRaw.toString()) ?? 0.0;

    final dynamic stockRaw = json['stock'];
    final int stockParsed =
        stockRaw == null ? 0 : int.tryParse(stockRaw.toString()) ?? 0;

    final category = json['category'];

    return Product(
      id: idParsed,
      name: json['name']?.toString() ?? '',
      categoryId: catIdParsed,
      categoryName: category != null ? category['name']?.toString() : null,
      stock: stockParsed,
      price: priceParsed,
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  // KIRIM KE API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'stock': stock,
      'price': price,
      'description': description,
    };
  }
}
