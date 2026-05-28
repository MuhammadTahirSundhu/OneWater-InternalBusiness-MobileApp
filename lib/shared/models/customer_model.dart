class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? area;
  final String? notes;
  final double totalPending;
  final double lifetimeValue;
  final String? createdBy;
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.area,
    this.notes,
    this.totalPending = 0,
    this.lifetimeValue = 0,
    this.createdBy,
    required this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      area: json['area'] as String?,
      notes: json['notes'] as String?,
      totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0,
      lifetimeValue: (json['lifetime_value'] as num?)?.toDouble() ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    'area': area,
    'notes': notes,
  };

  bool get hasPendingBalance => totalPending > 0;
}
