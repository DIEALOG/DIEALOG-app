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
    expect(invited.stakeholderId, person.id);
    expect(invited.status, ConfirmerStatus.pending);
    expect(
      (await transitions.listConfirmers()).any(
        (item) => item.id == invited.id && item.isActive,
      ),
      isTrue,
    );

    await transitions.resend(invited.id);
    await transitions.revoke(invited.id);
    expect(
      (await transitions.listConfirmers())
          .firstWhere((item) => item.id == invited.id)
          .isActive,
      isFalse,
    );
    dio.close();
  });
}
