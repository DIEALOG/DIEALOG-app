import 'package:diealog_app/core/network/auth_interceptor.dart';
import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/account_handling_task.dart';
import 'package:diealog_app/data/models/transition_case.dart';
import 'package:diealog_app/data/repositories/confirmer_repository.dart';
import 'package:diealog_app/data/repositories/stakeholder_repository.dart';
import 'package:diealog_app/data/repositories/stakeholder_task_repository.dart';
import 'package:diealog_app/data/repositories/transition_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'confirmed case issues a one-time task code and accepts a result',
    () async {
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
          MockApiInterceptor(
            backend: MockBackend.seeded(),
            latency: Duration.zero,
          ),
        );
      final people = StakeholderRepository(dio);
      final transition = TransitionRepository(dio);
      final confirmer = ConfirmerRepository(dio);
      final stakeholderTasks = StakeholderTaskRepository(dio);

      // A zero-day waiting period reaches the confirmed state in the fake API.
      await transition.updatePolicy(minimumConfirmers: 1, waitingPeriodDays: 0);
      final invite = await transition.invite((await people.list()).first);
      final access = await confirmer.acceptInvitation(invite.token);
      final item = await confirmer.startCase(access.authToken);
      await confirmer.confirm(
        access.authToken,
        item.id,
        TransitionDecision.agree,
      );
      expect(
        (await transition.getCase(item.id)).status,
        TransitionCaseStatus.confirmed,
      );

      final tasks = await transition.listTasks(item.id);
      expect(tasks, isNotEmpty);
      final task = tasks.firstWhere((entry) => entry.canRequest);
      final issued = await transition.requestTask(task.id);
      expect(issued.task.status, AccountHandlingStatus.inProgress);
      expect(issued.requests, isNotEmpty);
      expect(issued.requests.first.token, isNotEmpty);

      final result = await stakeholderTasks.submitResult(
        issued.requests.first.token,
        success: true,
      );
      expect(result.status, AccountHandlingStatus.completed);
      final publicRequest = requests.last;
      expect(publicRequest.path, '/transition/stakeholder-tasks/result');
      expect(publicRequest.extra[AuthInterceptor.skipAuth], isTrue);
      dio.close();
    },
  );
}
