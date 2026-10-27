import 'package:diealog_app/core/network/api_exception.dart';
import 'package:diealog_app/data/models/account.dart';
import 'package:diealog_app/data/models/json.dart';
import 'package:diealog_app/data/models/legacy.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the legacy list with nested accounts', () {
    final legacies = parseList([
      {
        'id': 'l1',
        'name': 'SNS',
        'created_at': '2026-10-01T09:00:00Z',
        'accounts': [
          {
            'id': 'a1',
            'name': '개인 계정',
            'type': {'type': 'KakaoTalk'},
            'action': {'action': 'backup-and-delete', 'message': '백업'},
            'stakeholder_ids': ['s1'],
            'stakeholder_group_ids': ['g1'],
          },
        ],
      },
    ], Legacy.fromJson);

    final legacy = legacies.single;
    final account = legacy.accounts.single;
    expect(legacy.createdAt, DateTime.utc(2026, 10, 1, 9));
    expect(account.name, '개인 계정');
    expect(account.type!.service, AccountService.kakaoTalk);
    expect(account.type!.label, '카카오톡');
    expect(account.action!.kind, AccountActionKind.backupAndDelete);
    expect(account.stakeholderIds, ['s1']);
    expect(account.stakeholderGroupIds, ['g1']);
    expect(account.hasAudience, isTrue);
  });

  test('unknown enum values fall back to other', () {
    final account = Account.fromJson({
      'name': '기타 계정',
      'type': {'type': 'Naver', 'name': 'Naver'},
      'action': {'action': 'archive'},
    });
    expect(account.type!.service, AccountService.other);
    expect(account.type!.label, 'Naver');
    expect(account.action!.kind, AccountActionKind.other);
    expect(account.hasAudience, isFalse);
  });

  test('request bodies use wire names and drop unset fields', () {
    const account = Account(
      name: '업무 계정',
      type: AccountType(service: AccountService.gitHub),
      action: AccountAction(kind: AccountActionKind.permissionMove),
      accountId: 'me',
      stakeholderIds: ['s1'],
    );
    expect(account.toJson(), {
      'name': '업무 계정',
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
