// MOCK: the backend has no endpoints to edit the profile, change the password
// or delete the user yet.

abstract interface class SettingsRepository {
  Future<void> updateName(String name);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> deleteUser();
}

class MockSettingsRepository implements SettingsRepository {
  static const _latency = Duration(milliseconds: 300);

  @override
  Future<void> updateName(String name) => Future.delayed(_latency);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      Future.delayed(_latency);

  @override
  Future<void> deleteUser() => Future.delayed(_latency);
}
