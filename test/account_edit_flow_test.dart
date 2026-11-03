import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/core/network/api_exception.dart';
import 'package:diealog_app/data/models/account.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/repositories/legacy_repository.dart';
import 'package:diealog_app/data/repositories/stakeholder_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'changing an account audience keeps credentials and removes old copy',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
        ..interceptors.add(
          MockApiInterceptor(
            backend: MockBackend.seeded(),
            latency: Duration.zero,
          ),
        );
      addTearDown(dio.close);
      final legacies = LegacyRepository(dio, allowAccountReplacement: true);
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

      final saved = await legacies.replaceAccount(
        owner.id,
        original.copyWith(stakeholderIds: [person.id]),
      );
      final detail = await legacies.getAccount(owner.id, saved.id);
      final listed = await legacies.list();

      expect(detail.stakeholderIds, [person.id]);
      expect(detail.accountPassword, 'test-password');
      expect(
        listed.singleWhere((legacy) => legacy.id == owner.id).accounts,
        hasLength(1),
      );
      expect(saved.id, isNot(original.id));
    },
  );

  test('live account replacement is rejected before writing', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    addTearDown(dio.close);
    final legacies = LegacyRepository(dio);

    await expectLater(
      legacies.replaceAccount('legacy-id', const Account(name: '기존 계정')),
      throwsA(isA<ApiException>()),
    );
  });
}
