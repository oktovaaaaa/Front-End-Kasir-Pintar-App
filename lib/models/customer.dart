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

  // ===== COPYWITH =====
  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? company,
    String? note,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      company: company ?? this.company,
      note: note ?? this.note,
    );
  }

  // ===== FROM JSON =====
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

  // ===== TO JSON =====
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'company': company,
      'note': note,
    };
  }
}
