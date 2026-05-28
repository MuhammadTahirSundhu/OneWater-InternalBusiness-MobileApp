class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^(03\d{9}|\+923\d{9})$').hasMatch(cleaned)) {
      return 'Enter a valid Pakistani phone number';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.trim().isEmpty) return 'PIN is required';
    if (value.length != 4 || !RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'PIN must be 4 digits';
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
    return null;
  }

  static String? positiveInt(String? value, [String fieldName = 'Quantity']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return '$fieldName must be greater than 0';
    return null;
  }
}
