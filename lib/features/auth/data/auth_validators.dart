/// Form validators shared by the login and reset-password screens.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?\d{10,13}$');

  static String? loginId(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email ID or contact number';
    final compact = v.replaceAll(RegExp(r'[\s-]'), '');
    if (!_email.hasMatch(v) && !_phone.hasMatch(compact)) return 'Enter a valid email ID or contact number';
    return null;
  }

  static String? password(String? value) => (value ?? '').isEmpty ? 'Enter your password' : null;

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a new password';
    if (v.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? otp(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter the OTP';
    if (!RegExp(r'^\d{4,8}$').hasMatch(v)) return 'Enter the OTP sent to you';
    return null;
  }
}
