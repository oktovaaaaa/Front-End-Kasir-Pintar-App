class SaleItem {
  final int id;
  final int productId;
  final String productName;
  final int qty;
  final double price;
  final double subtotal;

  SaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.price,
    required this.subtotal,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    final dynamic priceRaw = json['price'];
    final dynamic subtotalRaw = json['subtotal'];

    final product = json['product'];

    return SaleItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      productId: int.tryParse(json['product_id'].toString()) ?? 0,
      productName: product != null
          ? (product['name']?.toString() ?? '')
          : (json['product_name']?.toString() ?? ''),
      qty: int.tryParse(json['qty'].toString()) ?? 0,
      price: double.tryParse(priceRaw.toString()) ?? 0,
      subtotal: double.tryParse(subtotalRaw.toString()) ?? 0,
    );
  }
}

class Sale {
  final int id;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final String status; // paid / kasbon
  final String? customerName;
  final DateTime createdAt;
  final List<SaleItem> items;

  Sale({
    required this.id,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.status,
    required this.customerName,
    required this.createdAt,
    required this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    final dynamic totalRaw = json['total_amount'];
    final dynamic paidRaw = json['paid_amount'];
    final dynamic changeRaw = json['change_amount'];

    final List itemsJson = json['items'] as List? ?? [];

    return Sale(
      id: int.tryParse(json['id'].toString()) ?? 0,
      totalAmount: double.tryParse(totalRaw.toString()) ?? 0,
      paidAmount: double.tryParse(paidRaw.toString()) ?? 0,
      changeAmount: double.tryParse(changeRaw.toString()) ?? 0,
      status: json['status']?.toString() ?? 'paid',
      customerName: json['customer_name_snapshot']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'].toString()) ??
          DateTime.now(),
      items: itemsJson.map((e) => SaleItem.fromJson(e)).toList(),
    );
  }
}
