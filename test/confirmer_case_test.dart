import 'package:diealog_app/core/network/auth_interceptor.dart';
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
  test(
    'two accepted confirmers can move a case into the waiting period',
    () async {
      final backend = MockBackend.seeded();
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.next(options);
            },
          ),
        )
        ..interceptors.add(
          MockApiInterceptor(backend: backend, latency: Duration.zero),
        );
      final people = StakeholderRepository(dio);
      final transitions = TransitionRepository(dio);
      final confirmer = ConfirmerRepository(dio);

      final first = await people.create(
        const Stakeholder(name: '첫째', email: 'first@example.com'),
      );
      final second = await people.create(
        const Stakeholder(name: '둘째', email: 'second@example.com'),
      );
      final firstInvite = await transitions.invite(first);
      final secondInvite = await transitions.invite(second);
      final firstAccess = await confirmer.acceptInvitation(firstInvite.token);
      final secondAccess = await confirmer.acceptInvitation(secondInvite.token);

      final created = await confirmer.startCase(firstAccess.authToken);
      expect(created.status, TransitionCaseStatus.pendingConfirmation);
      expect(
        (await confirmer.listCases(secondAccess.authToken)).single.id,
        created.id,
      );
      await confirmer.confirm(
        firstAccess.authToken,
        created.id,
        TransitionDecision.agree,
      );
      expect(
        (await confirmer.getCase(firstAccess.authToken, created.id)).status,
        TransitionCaseStatus.pendingConfirmation,
      );
      await confirmer.confirm(
        secondAccess.authToken,
        created.id,
        TransitionDecision.agree,
      );
      expect(
        (await confirmer.getCase(firstAccess.authToken, created.id)).status,
        TransitionCaseStatus.waitingPeriod,
      );

      final caseRequest = requests.firstWhere(
        (request) =>
            request.path == '/transition/confirmer/cases' &&
            request.method == 'POST',
      );
      expect(caseRequest.headers['X-Confirmer-Token'], firstAccess.authToken);
      expect(caseRequest.extra[AuthInterceptor.skipAuth], isTrue);
      dio.close();
    },
  );
}
