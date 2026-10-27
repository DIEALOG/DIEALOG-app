/// Build-time configuration, overridable with `--dart-define`.
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api --dart-define=MOCK_API=false
/// ```
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://diealog.shxin.kr/api',
  );

  /// Answers every request from `MockBackend` with spec-shaped data instead of
  /// calling [apiBaseUrl]. Off by default now that the server is up; pass
  /// `--dart-define=MOCK_API=true` to work offline.
  static const useMockApi = bool.fromEnvironment('MOCK_API');
}
