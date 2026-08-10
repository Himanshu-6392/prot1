class AppValidators {
  AppValidators._();

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 10) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.\w{2,}$');
    if (!re.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? aadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhaar number is required';
    }
    final clean = value.replaceAll(RegExp(r'\s'), '');
    if (clean.length != 12 || !RegExp(r'^\d{12}$').hasMatch(clean)) {
      return 'Enter a valid 12-digit Aadhaar number';
    }
    return null;
  }

  static String? pan(String? value) {
    if (value == null || value.trim().isEmpty) return 'PAN number is required';
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.toUpperCase())) {
      return 'Enter a valid PAN number (e.g., ABCDE1234F)';
    }
    return null;
  }

  static String? amount(String? value, {int min = 1000, int max = 10000000}) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final num = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
    if (num == null) return 'Enter a valid amount';
    if (num < min) return 'Minimum amount is ₹$min';
    if (num > max) return 'Maximum amount is ₹$max';
    return null;
  }

  static String? interestRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Interest rate is required';
    }
    final d = double.tryParse(value);
    if (d == null) return 'Enter a valid interest rate';
    if (d < 0.5) return 'Minimum interest rate is 0.5%';
    if (d > 20) return 'Maximum interest rate is 20%';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? gst(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(value.toUpperCase())) {
      return 'Enter a valid GST number';
    }
    return null;
  }
}
