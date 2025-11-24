class Customer {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? company;
  final String? note;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.company,
    this.note,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      company: json['company']?.toString(),
      note: json['note']?.toString(),
    );
  }
}
