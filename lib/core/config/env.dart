/// Build-time configuration, overridable with `--dart-define`.
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://localhost:8080/api
/// ```
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://diealog.shxin.kr/api',
  );
}
