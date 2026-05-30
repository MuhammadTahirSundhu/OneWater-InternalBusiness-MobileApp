class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final String category;
  final String expenseDate;
  final String? notes;
  final String? recordedBy;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    this.notes,
    this.recordedBy,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String? ?? 'other',
      expenseDate: json['expense_date'] as String,
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case 'fuel':        return 'Fuel';
      case 'salary':      return 'Salary';
      case 'utilities':   return 'Utilities';
      case 'office':      return 'Office';
      case 'maintenance': return 'Maintenance';
      case 'other':       return 'Other';
      default: return category;
    }
  }

  String get categoryEmoji {
    switch (category) {
      case 'fuel':        return '⛽';
      case 'salary':      return '💼';
      case 'utilities':   return '💡';
      case 'office':      return '🖊️';
      case 'maintenance': return '🔧';
      case 'other':       return '📋';
      default: return '📋';
    }
  }

  static const List<Map<String, String>> allCategories = [
    {'value': 'fuel',        'label': 'Fuel',        'emoji': '⛽'},
    {'value': 'salary',      'label': 'Salary',      'emoji': '💼'},
    {'value': 'utilities',   'label': 'Utilities',   'emoji': '💡'},
    {'value': 'office',      'label': 'Office',      'emoji': '🖊️'},
    {'value': 'maintenance', 'label': 'Maintenance', 'emoji': '🔧'},
    {'value': 'other',       'label': 'Other',       'emoji': '📋'},
  ];
}

class AmountInModel {
  final String id;
  final String description;
  final double amount;
  final String? notes;
  final String? recordedBy;
  final String recordedDate;
  final DateTime createdAt;

  AmountInModel({
    required this.id,
    required this.description,
    required this.amount,
    this.notes,
    this.recordedBy,
    required this.recordedDate,
    required this.createdAt,
  });

  factory AmountInModel.fromJson(Map<String, dynamic> json) {
    return AmountInModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by'] as String?,
      recordedDate: json['recorded_date'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
