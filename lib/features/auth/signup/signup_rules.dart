abstract final class SignupRules {
  static final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool nameOk(String value) => value.trim().isNotEmpty;

  static bool emailOk(String value) => emailPattern.hasMatch(value.trim());

  static bool passwordLongEnough(String value) => value.length >= 8;

  static bool passwordHasLetterAndDigit(String value) =>
      RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);

  static bool passwordOk(String value) =>
      passwordLongEnough(value) && passwordHasLetterAndDigit(value);

  static bool passwordsMatch(String a, String b) =>
      a.isNotEmpty && a == b;

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String formatPhone(String value) {
    final digits = digitsOnly(value);
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    final end = digits.length > 11 ? 11 : digits.length;
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, end)}';
  }

  static bool phoneOk(String value) {
    final digits = digitsOnly(value);
    return digits.length == 11 && digits.startsWith('01');
  }
}
