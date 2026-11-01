import 'package:diealog_app/core/links/incoming_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps invitation and task deep links', () {
    expect(
      IncomingLink.locationOf(Uri.parse('diealog://invitation?token=abc')),
      '/invitation?token=abc',
    );
    expect(
      IncomingLink.locationOf(
        Uri.parse('https://diealog.shxin.kr/invitation?token=abc'),
      ),
      '/invitation?token=abc',
    );
    expect(
      IncomingLink.locationOf(Uri.parse('diealog://task?token=xyz')),
      '/task-result?token=xyz',
    );
    expect(IncomingLink.locationOf(Uri.parse('https://example.com/other')), isNull);
  });
}
