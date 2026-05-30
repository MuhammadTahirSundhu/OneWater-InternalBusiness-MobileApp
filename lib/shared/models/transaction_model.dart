class TransactionItemModel {
  final String? id;
  final String? transactionId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  TransactionItemModel({
    this.id,
    this.transactionId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['id'] as String?,
      transactionId: json['transaction_id'] as String?,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      lineTotal: (json['line_total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'line_total': lineTotal,
  };
}

class TransactionModel {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? createdBy;
  final String? createdByName;
  final DateTime transactionDate;
  final DateTime? dueDate;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final double amountPaid;
  final String paymentStatus;
  final String? paymentMethod;
  final String? notes;
  final String? invoicePdfUrl;
  final List<TransactionItemModel> items;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.createdBy,
    this.createdByName,
    required this.transactionDate,
    this.dueDate,
    required this.subtotal,
    this.discount = 0,
    required this.totalAmount,
    this.amountPaid = 0,
    required this.paymentStatus,
    this.paymentMethod,
    this.notes,
    this.invoicePdfUrl,
    this.items = const [],
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      createdBy: json['created_by'] as String?,
      createdByName: json['created_by_name'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['payment_status'] as String,
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      invoicePdfUrl: json['invoice_pdf_url'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TransactionItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  double get outstandingBalance => totalAmount - amountPaid;
  bool get isFullyPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';
  bool get isPartial => paymentStatus == 'partial';
  bool get isVoided => paymentStatus == 'voided';

  bool get isOverdue {
    if (isFullyPaid || isVoided) return false;
    return DateTime.now().difference(transactionDate).inDays > 7;
  }

  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case 'paid': return 'Paid';
      case 'pending': return 'Pending';
      case 'partial': return 'Partial';
      case 'voided': return 'Voided';
      default: return paymentStatus;
    }
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'cash': return 'Cash';
      case 'bank_transfer': return 'Bank Transfer';
      case 'easypaisa': return 'EasyPaisa';
      case 'jazzcash': return 'JazzCash';
      case 'credit': return 'Credit';
      default: return paymentMethod ?? '';
    }
  }

  String get itemsSummary {
    if (items.isEmpty) return '';
    if (items.length == 1) {
      return '${items[0].productName} ×${items[0].quantity}';
    }
    return '${items.length} items';
  }
}
