import 'package:diealog_app/core/network/api_exception.dart';
import 'package:diealog_app/data/models/account.dart';
import 'package:diealog_app/data/models/legacy.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a paginated legacy with nested accounts', () {
    final page = Paginated.fromJson({
      'items': [
        {
          'id': 'l1',
          'name': 'SNS',
          'created_at': '2026-10-01T09:00:00Z',
          'accounts': [
            {
              'id': 'a1',
              'type': {'type': 'KakaoTalk'},
              'action': {'action': 'backup-and-delete', 'message': '백업'},
              'stakeholder_ids': ['s1'],
            },
          ],
        },
      ],
      'total': 3,
      'limit': 1,
      'offset': 0,
    }, Legacy.fromJson);

    final legacy = page.items.single;
    final account = legacy.accounts.single;
    expect(legacy.createdAt, DateTime.utc(2026, 10, 1, 9));
    expect(account.type!.service, AccountService.kakaoTalk);
    expect(account.action!.kind, AccountActionKind.backupAndDelete);
    expect(account.stakeholderIds, ['s1']);
    expect(page.hasMore, isTrue);
  });

  test('unknown enum values fall back to other', () {
    final account = Account.fromJson({
      'type': {'type': 'Naver'},
      'action': {'action': 'archive'},
    });
    expect(account.type!.service, AccountService.other);
    expect(account.action!.kind, AccountActionKind.other);
  });

  test('request bodies use wire names and drop unset fields', () {
    const account = Account(
      type: AccountType(service: AccountService.gitHub),
      action: AccountAction(kind: AccountActionKind.permissionMove),
      accountId: 'me',
      stakeholderIds: ['s1'],
    );
    expect(account.toJson(), {
      'type': {'type': 'GitHub'},
      'action': {'action': 'permission-move'},
      'account_id': 'me',
      'stakeholder_ids': ['s1'],
    });
    expect(const Stakeholder(name: '엄마').toJson(), {
      'name': '엄마',
      'group_ids': <String>[],
    });
  });

  test('ApiException hides 5xx bodies but keeps 4xx messages', () {
    DioException withResponse(int status, Object body) {
      final options = RequestOptions(path: '/login');
      return DioException.badResponse(
        statusCode: status,
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: status,
          data: body,
        ),
      );
    }

    final server = ApiException.fromDio(
      withResponse(500, 'runtime error: invalid memory address'),
    );
    expect(server.message, isNot(contains('runtime error')));

    final client = ApiException.fromDio(
      withResponse(401, {'message': 'invalid credentials'}),
    );
    expect(client.message, 'invalid credentials');
    expect(client.isUnauthorized, isTrue);
  });
}
