class ProductModel {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double unitPrice;
  final double securityDeposit;
  final bool isActive;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.unitPrice,
    this.securityDeposit = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      category: json['category'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sku': sku,
    'category': category,
    'unit_price': unitPrice,
    'security_deposit': securityDeposit,
  };

  bool get hasSecurityDeposit => securityDeposit > 0;

  String get categoryDisplayName {
    switch (category) {
      case 'bottle_pack_500ml': return '500ml Pack';
      case 'bottle_1_5L': return '1.5L Bottle';
      case 'bottle_19L_new': return '19L New';
      case 'bottle_19L_refill': return '19L Refill';
      default: return category;
    }
  }

  String get emoji {
    switch (category) {
      case 'bottle_pack_500ml': return '🧴';
      case 'bottle_1_5L': return '🍶';
      case 'bottle_19L_new': return '🫙';
      case 'bottle_19L_refill': return '♻️';
      default: return '📦';
    }
  }
}
