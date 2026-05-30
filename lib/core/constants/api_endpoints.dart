class ApiEndpoints {
  ApiEndpoints._();

  // Base URL — Production server on Render
  static const String baseUrl = 'https://onewater-internalbusiness-mobileapp.onrender.com';
  // Uncomment below and comment above for local development with emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000';

  static const String apiVersion = '/api/v1';

  // Auth
  static const String login = '$apiVersion/auth/login';
  static const String logout = '$apiVersion/auth/logout';
  static const String refreshToken = '$apiVersion/auth/refresh';
  static const String me = '$apiVersion/auth/me';
  static const String changePassword = '$apiVersion/auth/change-password';

  // Users
  static const String users = '$apiVersion/users/';
  static String user(String id) => '$apiVersion/users/$id';

  // Customers
  static const String customers = '$apiVersion/customers/';
  static const String pendingCustomers = '$apiVersion/customers/pending';
  static String customer(String id) => '$apiVersion/customers/$id';
  static String customerTransactions(String id) => '$apiVersion/customers/$id/transactions';

  // Products
  static const String products = '$apiVersion/products/';
  static String product(String id) => '$apiVersion/products/$id';

  // Transactions
  static const String transactions = '$apiVersion/transactions/';
  static String transaction(String id) => '$apiVersion/transactions/$id';
  static String collectPayment(String id) => '$apiVersion/transactions/$id/collect-payment';
  static String invoice(String id) => '$apiVersion/transactions/$id/invoice';
  static String regenerateInvoice(String id) => '$apiVersion/transactions/$id/regenerate-invoice';

  // Reports
  static const String reportSummary = '$apiVersion/reports/summary';
  static const String reportSalesByPeriod = '$apiVersion/reports/sales-by-period';
  static const String reportSalesByProduct = '$apiVersion/reports/sales-by-product';
  static const String reportPaymentStatus = '$apiVersion/reports/payment-status';
  static const String reportTopCustomers = '$apiVersion/reports/top-customers';
  static const String reportOverdue = '$apiVersion/reports/overdue';
  static const String reportRevenueTrend = '$apiVersion/reports/revenue-trend';
  static const String reportCollectionEfficiency = '$apiVersion/reports/collection-efficiency';

  // Notifications
  static const String notifications = '$apiVersion/notifications/';
  static String markNotificationRead(String id) => '$apiVersion/notifications/$id/read';
  static const String markAllRead = '$apiVersion/notifications/mark-all-read';
  static const String triggerOverdueCheck = '$apiVersion/notifications/trigger-overdue-check';

  // Audit Logs
  static const String auditLogs = '$apiVersion/audit-logs/';
  static String auditLog(String id) => '$apiVersion/audit-logs/$id';

  // Settings
  static const String settings = '$apiVersion/settings/';
  static String setting(String key) => '$apiVersion/settings/$key';
}
