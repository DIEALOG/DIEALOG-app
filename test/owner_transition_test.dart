import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/models/transition_case.dart';
import 'package:diealog_app/data/repositories/confirmer_repository.dart';
import 'package:diealog_app/data/repositories/stakeholder_repository.dart';
import 'package:diealog_app/data/repositories/transition_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('owner can inspect and cancel a confirmer-started transition', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    final people = StakeholderRepository(dio);
    final transition = TransitionRepository(dio);
    final confirmer = ConfirmerRepository(dio);

    final person = await people.create(
      const Stakeholder(name: '확인자', email: 'helper@example.com'),
    );
    final invitation = await transition.invite(person);
    final access = await confirmer.acceptInvitation(invitation.token);
    final created = await confirmer.startCase(access.authToken);

    expect((await transition.listCases()).single.id, created.id);
    expect((await transition.getCase(created.id)).canCancel, isTrue);
    expect(await transition.listConfirmations(created.id), isEmpty);

    await confirmer.confirm(
      access.authToken,
      created.id,
      TransitionDecision.agree,
    );
    expect(
      (await transition.listConfirmations(created.id)).single.decision,
      TransitionDecision.agree,
    );
    expect(
      (await transition.cancelCase(created.id)).status,
      TransitionCaseStatus.cancelled,
    );
    expect((await transition.getCase(created.id)).canCancel, isFalse);
    dio.close();
  });

  test('alive check response creates the next scheduled check', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    final transition = TransitionRepository(dio);
    final first = (await transition.listAliveChecks()).single;
    expect(first.canRespond, isTrue);
    expect((await transition.scheduleAliveCheck()).id, first.id);

    final responded = await transition.respondAliveCheck(first.id);
    expect(responded.status.wire, 'responded');
    final checks = await transition.listAliveChecks();
    expect(checks.length, 2);
    expect(checks.first.sequence, first.sequence + 1);
    expect(checks.first.status.wire, 'scheduled');
    dio.close();
  });
}
