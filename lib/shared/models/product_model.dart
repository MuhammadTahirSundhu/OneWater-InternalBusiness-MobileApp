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
      case 'bottle_pack_500ml':    return '500ml Pack (12 Bottles)';
      case 'bottle_1_5L':          return '1500ml Pack (6 Bottles)';
      case 'bottle_19L_new':       return 'Mineral Water (19L New)';
      case 'bottle_19L_refill':    return 'Mineral Water (19L Refill)';
      case 'refill_filter_water':  return 'Refill Filter Water';
      case 'mineral_water':        return 'Mineral Water';
      default: return category;
    }
  }

  String get emoji {
    switch (category) {
      case 'bottle_pack_500ml':    return '🧴';
      case 'bottle_1_5L':          return '🍶';
      case 'bottle_19L_new':       return '🫙';
      case 'bottle_19L_refill':    return '♻️';
      case 'refill_filter_water':  return '🔵';
      case 'mineral_water':        return '💧';
      default: return '📦';
    }
  }

  static const List<Map<String, String>> allCategories = [
    {'value': 'bottle_pack_500ml',   'label': '500ml Pack (12 Bottles)',     'emoji': '🧴'},
    {'value': 'bottle_1_5L',         'label': '1500ml Pack (6 Bottles)',      'emoji': '🍶'},
    {'value': 'bottle_19L_new',      'label': 'Mineral Water (19L New)',      'emoji': '🫙'},
    {'value': 'bottle_19L_refill',   'label': 'Mineral Water (19L Refill)',   'emoji': '♻️'},
    {'value': 'refill_filter_water', 'label': 'Refill Filter Water',          'emoji': '🔵'},
    {'value': 'mineral_water',       'label': 'Mineral Water',                'emoji': '💧'},
  ];
}
