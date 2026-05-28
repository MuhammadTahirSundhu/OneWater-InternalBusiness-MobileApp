class ReportSummary {
  final double todaySales;
  final int todayTransactions;
  final double monthSales;
  final double monthCollected;
  final double totalPending;
  final int pendingTransactions;
  final int pendingCustomers;

  ReportSummary({
    required this.todaySales,
    required this.todayTransactions,
    required this.monthSales,
    required this.monthCollected,
    required this.totalPending,
    required this.pendingTransactions,
    required this.pendingCustomers,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0,
      todayTransactions: json['today_transactions'] as int? ?? 0,
      monthSales: (json['month_sales'] as num?)?.toDouble() ?? 0,
      monthCollected: (json['month_collected'] as num?)?.toDouble() ?? 0,
      totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0,
      pendingTransactions: json['pending_transactions'] as int? ?? 0,
      pendingCustomers: json['pending_customers'] as int? ?? 0,
    );
  }
}

class SalesByProductItem {
  final String product;
  final double revenue;
  final int quantity;

  SalesByProductItem({
    required this.product,
    required this.revenue,
    required this.quantity,
  });

  factory SalesByProductItem.fromJson(Map<String, dynamic> json) {
    return SalesByProductItem(
      product: json['product'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}

class PaymentBreakdown {
  final String status;
  final double amount;
  final double percentage;
  final int count;

  PaymentBreakdown({
    required this.status,
    required this.amount,
    required this.percentage,
    required this.count,
  });

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdown(
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      count: json['count'] as int,
    );
  }
}

class DailyRevenue {
  final String date;
  final double revenue;
  final double collected;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.collected,
  });

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: json['date'] as String,
      revenue: (json['revenue'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble() ?? 0,
      collected: (json['collected'] as num?)?.toDouble() ?? 0,
    );
  }
}
