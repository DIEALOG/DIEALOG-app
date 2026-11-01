import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/models/transition_confirmer.dart';
import 'package:diealog_app/data/repositories/stakeholder_repository.dart';
import 'package:diealog_app/data/repositories/transition_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invites a saved stakeholder and updates the confirmer list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    final people = StakeholderRepository(dio);
    final transitions = TransitionRepository(dio);

    final person = await people.create(
      const Stakeholder(
        name: '최동훈',
        email: 'donghun@example.com',
        relationship: '친구',
      ),
    );
    final invited = await transitions.invite(person);
    expect(invited.confirmer.stakeholderId, person.id);
    expect(invited.confirmer.status, ConfirmerStatus.pending);
    expect(invited.token, isNotEmpty);
    expect(
      (await transitions.listConfirmers()).any(
        (item) => item.id == invited.confirmer.id && item.isActive,
      ),
      isTrue,
    );

    final resent = await transitions.resend(invited.confirmer.id);
    expect(resent.token, isNot(invited.token));
    await transitions.revoke(invited.confirmer.id);
    expect(
      (await transitions.listConfirmers())
          .firstWhere((item) => item.id == invited.confirmer.id)
          .isActive,
      isFalse,
    );
    dio.close();
  });
}
