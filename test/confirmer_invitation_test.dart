import 'package:diealog_app/core/storage/confirmer_session_store.dart';
import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/confirmer_access.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/models/transition_confirmer.dart';
import 'package:diealog_app/data/repositories/confirmer_repository.dart';
import 'package:diealog_app/data/repositories/stakeholder_repository.dart';
import 'package:diealog_app/data/repositories/transition_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'invitation is single-use and accepted token is stored separately',
    () async {
      final backend = MockBackend.seeded();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
        ..interceptors.add(
          MockApiInterceptor(backend: backend, latency: Duration.zero),
        );
      final person = await StakeholderRepository(dio)
          .create(const Stakeholder(name: '동훈', email: 'donghun@example.com'));
      final invitation = await TransitionRepository(dio).invite(person);
      final repo = ConfirmerRepository(dio);
      final access = await repo.acceptInvitation(invitation.token);
      expect(access.confirmer.status, ConfirmerStatus.accepted);
      expect(access.authToken, isNotEmpty);

      final store = InMemoryConfirmerSessionStore();
      await store.upsert(ConfirmerSession.fromAccess(access));
      expect((await store.read()).single.authToken, access.authToken);
      expect(
        (await store.read()).single.ownerUserId,
        access.confirmer.ownerUserId,
      );

      await expectLater(
        repo.acceptInvitation(invitation.token),
        throwsA(isA<Exception>()),
      );
      dio.close();
    },
  );

  test(
    'declining invalidates invitation and does not create a session',
    () async {
      final backend = MockBackend.seeded();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
        ..interceptors.add(
          MockApiInterceptor(backend: backend, latency: Duration.zero),
        );
      final person = await StakeholderRepository(dio)
          .create(const Stakeholder(name: '서연', phone: '01012345678'));
      final invitation = await TransitionRepository(dio).invite(person);
      final repo = ConfirmerRepository(dio);
      await repo.declineInvitation(invitation.token);
      await expectLater(
        repo.acceptInvitation(invitation.token),
        throwsA(isA<Exception>()),
      );
      dio.close();
    },
  );
}
