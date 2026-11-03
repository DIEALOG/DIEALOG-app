import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/account.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/repositories/legacy_repository.dart';
import 'package:diealog_app/data/repositories/stakeholder_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editing an audience keeps the account id and its password', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    addTearDown(dio.close);
    final legacies = LegacyRepository(dio);
    final stakeholders = StakeholderRepository(dio);
    final owner = await legacies.create('내 데이터');
    final person = await stakeholders.create(
      const Stakeholder(name: '받는 사람', email: 'recipient@example.com'),
    );
    final original = await legacies.addAccount(
      owner.id,
      const Account(
        name: '사진 보관함',
        type: AccountType(service: AccountService.other, name: 'iCloud'),
        action: AccountAction(kind: AccountActionKind.backupAndDelete),
        accountId: 'owner@example.com',
        accountPassword: 'test-password',
      ),
    );

    // The edit screen never loads the password into a field, so the request
    // body omits it; the stored credential has to survive anyway.
    final saved = await legacies.updateAccount(
      owner.id,
      Account(
        id: original.id,
        name: original.name,
        type: original.type,
        action: original.action,
        accountId: original.accountId,
        stakeholderIds: [person.id],
      ),
    );
    final detail = await legacies.getAccount(owner.id, saved.id);
    final listed = await legacies.list();

    expect(saved.id, original.id, reason: 'the account id must not change');
    expect(detail.stakeholderIds, [person.id]);
    expect(detail.accountPassword, 'test-password');
    expect(
      listed.singleWhere((legacy) => legacy.id == owner.id).accounts,
      hasLength(1),
      reason: 'an edit must not leave a duplicate behind',
    );
  });
}
