abstract final class SignupRules {
  static final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool nameOk(String value) => value.trim().isNotEmpty;

  static bool emailOk(String value) => emailPattern.hasMatch(value.trim());

  static bool passwordLongEnough(String value) => value.length >= 8;

  static bool passwordHasLetterAndDigit(String value) =>
      RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);

  static bool passwordOk(String value) =>
      passwordLongEnough(value) && passwordHasLetterAndDigit(value);

  static bool passwordsMatch(String a, String b) => a.isNotEmpty && a == b;

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String _domesticPhoneDigits(String value) {
    final digits = digitsOnly(value);
    // Phone autofill may return +82 instead of the domestic 0 prefix.
    if (digits.startsWith('82')) {
      return '0${digits.substring(2)}';
    }
    return digits;
  }

  static String formatPhone(String value) {
    final digits = _domesticPhoneDigits(value);
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }

  static bool phoneOk(String value) {
    return RegExp(r'^01[016789]\d{8}$').hasMatch(_domesticPhoneDigits(value));
  }
}
