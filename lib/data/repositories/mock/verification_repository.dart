// Kept as the interface the signup flow talks to. The live implementation
// is PhoneVerificationRepository; this mock is for unit tests only.

abstract interface class VerificationRepository {
  Future<void> sendCode(String email);

  /// Returns whether [code] is accepted for [email].
  Future<bool> verifyCode(String email, String code);
}

/// Accepts any 6-digit code.
class MockVerificationRepository implements VerificationRepository {
  @override
  Future<void> sendCode(String email) =>
      Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<bool> verifyCode(String email, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return RegExp(r'^\d{6}$').hasMatch(code);
  }
}
