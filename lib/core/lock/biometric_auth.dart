import 'package:local_auth/local_auth.dart';

/// Face ID / device credential gate. Missing plugins or hardware fail open
/// so emulators and desktop builds are not locked out.
class BiometricAuth {
  BiometricAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> canAuthenticate() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns true when the user passed, or when this device cannot prompt.
  Future<bool> authenticate(String reason) async {
    if (!await canAuthenticate()) return true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
