import '../models/json.dart';

/// Thrown for a request the fake backend answers with an error status.
class MockApiError implements Exception {
  const MockApiError(this.status, this.message);

  final int status;
  final String message;
}

class MockResult {
  const MockResult(this.status, this.data);

  final int status;
  final Object? data;
}

/// In-memory stand-in for the DIEALOG backend.
///
/// Entities are stored in the same JSON shape the Go handlers return, so the
/// app's models and repositories run unchanged against either backend. Only
/// the endpoints the app calls are implemented; anything else answers 404.
class MockBackend {
  MockBackend.seeded() {
    _seed();
  }

  final _stakeholders = <Json>[];
  final _groups = <Json>[];
  final _legacies = <Json>[];
  final _accounts = <Json>[];
  final _lastWords = <Json>[];
  final _confirmers = <Json>[];
  final _aliveChecks = <Json>[];
  final _invitationTokens = <String, String>{};
  final _confirmerTokens = <String, String>{};
  final _cases = <Json>[];
  final _confirmations = <Json>[];

  late Json _user;
  late Json _config;
  late Json _policy;

  var _seq = 0;

  String _id(String prefix) => '$prefix-${++_seq}';

  static String _now() => DateTime.now().toUtc().toIso8601String();

  static String _daysFromNow(int days) =>
      DateTime.now().toUtc().add(Duration(days: days)).toIso8601String();

  // --------------------------------------------------------------- dispatch

  MockResult handle(
    String method,
    String path,
    Object? body, {
    Map<String, dynamic> headers = const {},
  }) {
    final segments = path.split('?').first.split('/')
      ..removeWhere((s) => s.isEmpty);
    final data = body is Json ? body : const <String, dynamic>{};
    final verb = method.toUpperCase();

    String at(int i) => i < segments.length ? segments[i] : '';
    bool match(List<String> pattern) {
      if (pattern.length != segments.length) return false;
      for (var i = 0; i < pattern.length; i++) {
        if (pattern[i] != '*' && pattern[i] != segments[i]) return false;
      }
      return true;
    }

    // auth
    if (verb == 'POST' && match(['signup'])) return _signup(data);
    if (verb == 'POST' && match(['login'])) return _login(data);
    if (verb == 'POST' && match(['refresh'])) return MockResult(200, _tokens());

    if (verb == 'POST' && match(['transition', 'invitations', 'accept'])) {
      final token = data['token'] as String? ?? '';
      final confirmerId = _invitationTokens.remove(token);
      if (confirmerId == null) {
        throw const MockApiError(400, '초대 코드가 유효하지 않아요.');
      }
      final confirmer = _requireConfirmer(confirmerId);
      confirmer['status'] = 'accepted';
      confirmer['accepted_at'] = _now();
      final authToken = _id('confirmer-auth');
      _confirmerTokens[authToken] = confirmerId;
      return MockResult(200, {
        'confirmer': confirmer,
        'auth_token': authToken,
        'expires_at': _daysFromNow(30),
      });
    }
    if (verb == 'POST' && match(['transition', 'invitations', 'decline'])) {
      final token = data['token'] as String? ?? '';
      final confirmerId = _invitationTokens.remove(token);
      if (confirmerId == null) {
        throw const MockApiError(400, '초대 코드가 유효하지 않아요.');
      }
      final confirmer = _requireConfirmer(confirmerId);
      confirmer['status'] = 'declined';
      return const MockResult(200, {'message': 'invitation declined'});
    }

    if (match(['transition', 'confirmer', 'cases'])) {
      final confirmer = _requireConfirmerToken(headers);
      if (verb == 'GET') {
        return MockResult(200, [
          for (final item in _cases)
            if (item['user_id'] == confirmer['user_id'] &&
                item['status'] != 'cancelled')
              item,
        ]);
      }
      if (verb == 'POST') {
        if (_cases.any(
          (item) =>
              item['user_id'] == confirmer['user_id'] &&
              item['status'] != 'cancelled' &&
              item['status'] != 'confirmed',
        )) {
          throw const MockApiError(400, '이미 진행 중인 전환 절차가 있어요.');
        }
        final item = <String, dynamic>{
          'id': _id('case'),
          'user_id': confirmer['user_id'],
          'status': 'pending_confirmation',
          'minimum_confirmers_snapshot': _policy['minimum_confirmers'],
          'waiting_period_days_snapshot': _policy['waiting_period_days'],
          'requested_at': _now(),
          'created_at': _now(),
          'updated_at': _now(),
        };
        _cases.add(item);
        return MockResult(201, item);
      }
    }
    if (match(['transition', 'confirmer', 'cases', '*'])) {
      final confirmer = _requireConfirmerToken(headers);
      final item = _requireCase(at(3), confirmer['user_id'] as String);
      if (verb == 'GET') return MockResult(200, item);
    }
    if (verb == 'POST' &&
        match(['transition', 'confirmer', 'cases', '*', 'confirmations'])) {
      final confirmer = _requireConfirmerToken(headers);
      final item = _requireCase(at(3), confirmer['user_id'] as String);
      if (item['status'] != 'pending_confirmation') {
        throw const MockApiError(400, '확인 중인 절차에만 응답할 수 있어요.');
      }
      final decision = data['decision'] as String? ?? '';
      if (!['agree', 'disagree', 'abstain'].contains(decision)) {
        throw const MockApiError(400, '확인 결과가 올바르지 않아요.');
      }
      _confirmations.removeWhere(
        (entry) =>
            entry['transition_case_id'] == item['id'] &&
            entry['transition_confirmer_id'] == confirmer['id'],
      );
      final response = <String, dynamic>{
        'id': _id('confirmation'),
        'transition_case_id': item['id'],
        'transition_confirmer_id': confirmer['id'],
        'decision': decision,
        'comment': data['comment'],
        'responded_at': _now(),
        'created_at': _now(),
      };
      _confirmations.add(response);
      final agreed = _confirmations
          .where(
            (entry) =>
                entry['transition_case_id'] == item['id'] &&
                entry['decision'] == 'agree',
          )
          .length;
      if (agreed >= (item['minimum_confirmers_snapshot'] as int)) {
        item['status'] = 'waiting_period';
        item['waiting_started_at'] = _now();
      }
      return MockResult(200, response);
    }

    // profile
    if (verb == 'GET' && match(['profile', 'protected'])) {
      return MockResult(200, _profileJson());
    }
    if (verb == 'PUT' && match(['profile', 'protected', 'config'])) {
      _config = {..._config, ...data};
      return MockResult(200, _config);
    }

    // legacy
    if (match(['legacy', 'protected'])) {
      if (verb == 'GET') {
        return MockResult(200, [for (final l in _legacies) _legacyJson(l)]);
      }
      if (verb == 'POST') return _createLegacy(data);
    }
    if (match(['legacy', 'protected', '*'])) {
      final legacy = _requireLegacy(at(2));
      switch (verb) {
        case 'GET':
          return MockResult(200, _legacyJson(legacy));
        case 'PUT':
          legacy['name'] = data['name'] ?? legacy['name'];
          return MockResult(200, _legacyJson(legacy));
        case 'DELETE':
          _accounts.removeWhere((a) => a['legacy_id'] == legacy['id']);
          _legacies.remove(legacy);
          return const MockResult(200, {'message': 'deleted'});
      }
    }
    if (verb == 'POST' && match(['legacy', 'protected', '*', 'account'])) {
      return _createAccount(_requireLegacy(at(2)), data);
    }
    if (match(['legacy', 'protected', '*', 'account', '*'])) {
      _requireLegacy(at(2));
      final account = _requireAccount(at(4));
      if (verb == 'GET') return MockResult(200, _accountDetailJson(account));
      if (verb == 'DELETE') {
        _accounts.remove(account);
        return const MockResult(200, {'message': 'deleted'});
      }
    }

    // stakeholder groups are matched before the `/{id}` route
    if (match(['stakeholder', 'protected', 'group'])) {
      if (verb == 'GET') {
        return MockResult(200, [for (final g in _groups) _groupJson(g)]);
      }
      if (verb == 'POST') return _createGroup(data);
    }
    if (match(['stakeholder', 'protected', 'group', '*'])) {
      final group = _requireGroup(at(3));
      switch (verb) {
        case 'GET':
          return MockResult(200, _groupJson(group));
        case 'PUT':
          group['name'] = data['name'] ?? group['name'];
          group['stakeholder_ids'] =
              _ids(data['stakeholder_ids']) ?? group['stakeholder_ids'];
          return MockResult(200, _groupJson(group));
        case 'DELETE':
          _groups.remove(group);
          for (final a in _accounts) {
            (a['stakeholder_group_ids'] as List).remove(group['id']);
          }
          return const MockResult(200, {'message': 'deleted'});
      }
    }
    if (match(['stakeholder', 'protected'])) {
      if (verb == 'GET') {
        return MockResult(200, [
          for (final s in _stakeholders) _stakeholderJson(s),
        ]);
      }
      if (verb == 'POST') return _createStakeholder(data);
    }
    if (match(['stakeholder', 'protected', '*'])) {
      final stakeholder = _requireStakeholder(at(2));
      switch (verb) {
        case 'GET':
          return MockResult(200, _stakeholderJson(stakeholder));
        case 'PUT':
          for (final key in const [
            'name',
            'email',
            'phone',
            'relationship',
            'message',
          ]) {
            if (data.containsKey(key)) stakeholder[key] = data[key];
          }
          _setGroupsOf(stakeholder, _ids(data['group_ids']));
          return MockResult(200, _stakeholderJson(stakeholder));
        case 'DELETE':
          _stakeholders.remove(stakeholder);
          final id = stakeholder['id'];
          for (final g in _groups) {
            (g['stakeholder_ids'] as List).remove(id);
          }
          for (final a in _accounts) {
            (a['stakeholder_ids'] as List).remove(id);
          }
          return const MockResult(200, {'message': 'deleted'});
      }
    }

    // last word
    if (match(['last-word', 'protected'])) {
      if (verb == 'GET') {
        return MockResult(200, [for (final w in _lastWords) _lastWordJson(w)]);
      }
      if (verb == 'POST') return _createLastWord(data);
    }
    if (match(['last-word', 'protected', '*'])) {
      final word = _requireLastWord(at(2));
      switch (verb) {
        case 'GET':
          return MockResult(200, _lastWordJson(word));
        case 'PUT':
          word['title'] = data['title'] ?? word['title'];
          word['message'] = data['message'] ?? word['message'];
          word['receiver_ids'] =
              _ids(data['receiver_ids']) ?? word['receiver_ids'];
          word['receiver_group_ids'] =
              _ids(data['receiver_group_ids']) ?? word['receiver_group_ids'];
          return MockResult(200, _lastWordJson(word));
        case 'DELETE':
          _lastWords.remove(word);
          return const MockResult(200, {'message': 'deleted'});
      }
    }

    // transition
    if (match(['transition', 'protected', 'policy'])) {
      if (verb == 'GET') return MockResult(200, _policy);
      if (verb == 'PATCH') {
        for (final key in const [
          'minimum_confirmers',
          'waiting_period_days',
          'alive_check_interval_days',
        ]) {
          if (data[key] != null) _policy[key] = data[key];
        }
        _policy['updated_at'] = _now();
        return MockResult(200, _policy);
      }
    }
    if (match(['transition', 'protected', 'confirmers'])) {
      if (verb == 'GET') return MockResult(200, List<Json>.from(_confirmers));
      if (verb == 'POST') return _inviteConfirmer(data);
    }
    if (verb == 'DELETE' &&
        match(['transition', 'protected', 'confirmers', '*'])) {
      final confirmer = _requireConfirmer(at(3));
      confirmer['status'] = 'revoked';
      confirmer['revoked_at'] = _now();
      _invitationTokens.removeWhere((_, id) => id == at(3));
      _confirmerTokens.removeWhere((_, id) => id == at(3));
      return MockResult(200, confirmer);
    }
    if (verb == 'POST' &&
        match(['transition', 'protected', 'confirmers', '*', 'resend'])) {
      final confirmer = _requireConfirmer(at(3));
      confirmer['status'] = 'pending';
      confirmer['invited_at'] = _now();
      confirmer['invite_expires_at'] = _daysFromNow(7);
      _invitationTokens.removeWhere((_, id) => id == at(3));
      _confirmerTokens.removeWhere((_, id) => id == at(3));
      final token = _id('invite');
      _invitationTokens[token] = at(3);
      return MockResult(200, {
        'confirmer': confirmer,
        'invitation_token': token,
        'expires_at': _daysFromNow(7),
      });
    }
    if (match(['transition', 'protected', 'alive-checks'])) {
      if (verb == 'GET') {
        if (_aliveChecks.isEmpty) _scheduleAliveCheck();
        return MockResult(200, List<Json>.from(_aliveChecks.reversed));
      }
      if (verb == 'POST') return _scheduleAliveCheck();
    }
    if (verb == 'POST' &&
        match(['transition', 'protected', 'alive-checks', '*', 'respond'])) {
      final check = _find(_aliveChecks, at(3));
      if (check == null) throw const MockApiError(404, 'alive check not found');
      if (check['status'] == 'responded' || check['status'] == 'cancelled') {
        throw const MockApiError(400, '이미 종료된 생존 확인이에요.');
      }
      check['status'] = 'responded';
      check['responded_at'] = _now();
      _scheduleAliveCheck();
      return MockResult(200, check);
    }
    if (verb == 'GET' && match(['transition', 'protected', 'cases'])) {
      return MockResult(200, List<Json>.from(_cases));
    }
    if (match(['transition', 'protected', 'cases', '*'])) {
      final item = _requireCase(at(3), _user['id'] as String);
      if (verb == 'GET') return MockResult(200, item);
    }
    if (verb == 'POST' &&
        match(['transition', 'protected', 'cases', '*', 'cancel'])) {
      final item = _requireCase(at(3), _user['id'] as String);
      if (item['status'] != 'pending_confirmation' &&
          item['status'] != 'waiting_period') {
        throw const MockApiError(400, '취소할 수 없는 전환 절차예요.');
      }
      item['status'] = 'cancelled';
      item['cancelled_at'] = _now();
      return MockResult(200, item);
    }
    if (verb == 'GET' &&
        match(['transition', 'protected', 'cases', '*', 'confirmations'])) {
      final item = _requireCase(at(3), _user['id'] as String);
      return MockResult(200, [
        for (final entry in _confirmations)
          if (entry['transition_case_id'] == item['id']) entry,
      ]);
    }

    throw const MockApiError(404, '아직 준비되지 않은 요청이에요.');
  }

  // ------------------------------------------------------------- endpoints

  MockResult _signup(Json data) {
    _user = {
      ..._user,
      'name': data['name'] ?? _user['name'],
      'email': data['email'] ?? _user['email'],
      'phone_number': data['phone_number'] ?? _user['phone_number'],
    };
    return MockResult(200, _tokens());
  }

  MockResult _login(Json data) {
    final email = data['email'] as String? ?? '';
    final password = data['password'] as String? ?? '';
    if (email.isEmpty || password.isEmpty) {
      throw const MockApiError(401, '이메일 또는 비밀번호를 확인해 주세요.');
    }
    _user['email'] = email;
    return MockResult(200, _tokens());
  }

  Json _tokens() => {
    'accessToken': 'mock-access-${++_seq}',
    'refreshToken': 'mock-refresh-$_seq',
  };

  MockResult _createLegacy(Json data) {
    final legacy = <String, dynamic>{
      'id': _id('legacy'),
      'user_id': _user['id'],
      'name': data['name'] ?? '',
      'created_at': _now(),
    };
    _legacies.add(legacy);
    return MockResult(201, _legacyJson(legacy));
  }

  MockResult _createAccount(Json legacy, Json data) {
    final type = data['type'] is Json
        ? data['type'] as Json
        : const <String, dynamic>{};
    final action = data['action'] is Json
        ? data['action'] as Json
        : const <String, dynamic>{};
    final account = <String, dynamic>{
      'id': _id('account'),
      'legacy_id': legacy['id'],
      'name': data['name'] ?? '',
      'type': {'id': _id('type'), 'type': type['type'], 'name': type['name']},
      'action': {
        'id': _id('action'),
        'action': action['action'],
        'message': action['message'],
      },
      'account_id': data['account_id'],
      'account_password': data['account_password'],
      'data_location': data['data_location'],
      'stakeholder_ids': _ids(data['stakeholder_ids']) ?? <String>[],
      'stakeholder_group_ids':
          _ids(data['stakeholder_group_ids']) ?? <String>[],
      'created_at': _now(),
    };
    _accounts.add(account);
    return MockResult(201, _accountDetailJson(account));
  }

  MockResult _createStakeholder(Json data) {
    final stakeholder = <String, dynamic>{
      'id': _id('stakeholder'),
      'user_id': _user['id'],
      'name': data['name'] ?? '',
      'email': data['email'],
      'phone': data['phone'],
      'relationship': data['relationship'],
      'message': data['message'],
      'created_at': _now(),
    };
    _stakeholders.add(stakeholder);
    _setGroupsOf(stakeholder, _ids(data['group_ids']));
    return MockResult(201, _stakeholderJson(stakeholder));
  }

  MockResult _createGroup(Json data) {
    final group = <String, dynamic>{
      'id': _id('group'),
      'user_id': _user['id'],
      'name': data['name'] ?? '',
      'stakeholder_ids': _ids(data['stakeholder_ids']) ?? <String>[],
      'created_at': _now(),
    };
    _groups.add(group);
    return MockResult(201, _groupJson(group));
  }

  MockResult _createLastWord(Json data) {
    final word = <String, dynamic>{
      'id': _id('last-word'),
      'user_id': _user['id'],
      'title': data['title'] ?? '',
      'message': data['message'] ?? '',
      'receiver_ids': _ids(data['receiver_ids']) ?? <String>[],
      'receiver_group_ids': _ids(data['receiver_group_ids']) ?? <String>[],
    };
    _lastWords.add(word);
    return MockResult(201, _lastWordJson(word));
  }

  MockResult _inviteConfirmer(Json data) {
    final confirmer = <String, dynamic>{
      'id': _id('confirmer'),
      'user_id': _user['id'],
      'stakeholder_id': data['stakeholder_id'],
      'name': data['name'] ?? '',
      'email': data['email'],
      'phone': data['phone'],
      'status': 'pending',
      'invited_at': _now(),
      'invite_expires_at': _daysFromNow(7),
      'created_at': _now(),
      'updated_at': _now(),
    };
    _confirmers.add(confirmer);
    final token = _id('invite');
    _invitationTokens[token] = confirmer['id'] as String;
    return MockResult(201, {
      'confirmer': confirmer,
      'invitation_token': token,
      'expires_at': _daysFromNow(7),
    });
  }

  MockResult _scheduleAliveCheck() {
    if (_aliveChecks.isNotEmpty) {
      final latest = _aliveChecks.last;
      if (latest['status'] == 'scheduled' || latest['status'] == 'pending') {
        return MockResult(200, latest);
      }
      if (latest['status'] == 'overdue') {
        throw const MockApiError(400, '기한이 지난 생존 확인에 먼저 응답해 주세요.');
      }
    }
    final interval = _policy['alive_check_interval_days'] as int;
    final check = <String, dynamic>{
      'id': _id('alive-check'),
      'user_id': _user['id'],
      'sequence': _aliveChecks.length + 1,
      'scheduled_at': _daysFromNow(interval),
      'due_at': _daysFromNow(interval + 7),
      'status': 'scheduled',
      'created_at': _now(),
    };
    _aliveChecks.add(check);
    return MockResult(201, check);
  }

  // ----------------------------------------------------------------- views

  Json _profileJson() => {
    ..._user,
    'stakeholders': [for (final s in _stakeholders) _stakeholderJson(s)],
    'stakeholder_groups': [for (final g in _groups) _groupJson(g)],
  };

  Json _legacyJson(Json legacy) => {
    'id': legacy['id'],
    'name': legacy['name'],
    'user_id': legacy['user_id'],
    'accounts': [
      for (final a in _accounts)
        if (a['legacy_id'] == legacy['id']) _accountListJson(a),
    ],
    'created_at': legacy['created_at'],
  };

  Json _accountListJson(Json account) => {
    'id': account['id'],
    'legacy_id': account['legacy_id'],
    'type': account['type'],
    'name': account['name'],
    'action': account['action'],
    'stakeholder_ids': List<String>.from(account['stakeholder_ids'] as List),
    'stakeholder_group_ids': List<String>.from(
      account['stakeholder_group_ids'] as List,
    ),
    'created_at': account['created_at'],
  };

  Json _accountDetailJson(Json account) => {
    ..._accountListJson(account),
    'account_id': account['account_id'],
    'account_password': account['account_password'],
    'data_location': account['data_location'],
    'stakeholders': [
      for (final id in account['stakeholder_ids'] as List)
        ?_maybe(_stakeholders, id, _stakeholderJson),
    ],
    'stakeholder_groups': [
      for (final id in account['stakeholder_group_ids'] as List)
        ?_maybe(_groups, id, _groupJson),
    ],
  };

  Json _stakeholderJson(Json stakeholder) {
    final id = stakeholder['id'];
    final groups = [
      for (final g in _groups)
        if ((g['stakeholder_ids'] as List).contains(id)) g,
    ];
    return {
      ...stakeholder,
      'group_ids': [for (final g in groups) g['id']],
      'groups': [for (final g in groups) _plainGroupJson(g)],
    };
  }

  /// Group without its members, used where a stakeholder is already nested.
  Json _plainGroupJson(Json group) => {
    'id': group['id'],
    'user_id': group['user_id'],
    'name': group['name'],
    'stakeholder_ids': List<String>.from(group['stakeholder_ids'] as List),
    'created_at': group['created_at'],
  };

  Json _groupJson(Json group) => {
    ..._plainGroupJson(group),
    'stakeholders': [
      for (final id in group['stakeholder_ids'] as List)
        ?_maybe(_stakeholders, id, _plainStakeholderJson),
    ],
  };

  /// Stakeholder without its groups, used inside a group response.
  Json _plainStakeholderJson(Json stakeholder) => {
    'id': stakeholder['id'],
    'user_id': stakeholder['user_id'],
    'name': stakeholder['name'],
    'email': stakeholder['email'],
    'phone': stakeholder['phone'],
    'relationship': stakeholder['relationship'],
    'message': stakeholder['message'],
    'created_at': stakeholder['created_at'],
  };

  Json _lastWordJson(Json word) => {
    'id': word['id'],
    'user_id': word['user_id'],
    'title': word['title'],
    'message': word['message'],
    'receiver': [
      for (final id in word['receiver_ids'] as List)
        ?_maybe(_stakeholders, id, _stakeholderJson),
    ],
    'receiver_groups': [
      for (final id in word['receiver_group_ids'] as List)
        ?_maybe(_groups, id, _groupJson),
    ],
  };

  // ----------------------------------------------------------------- utils

  Json? _find(List<Json> source, Object? id) {
    for (final item in source) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  Json? _maybe(List<Json> source, Object? id, Json Function(Json) view) {
    final found = _find(source, id);
    return found == null ? null : view(found);
  }

  List<String>? _ids(Object? value) =>
      value is List ? value.whereType<String>().toList() : null;

  void _setGroupsOf(Json stakeholder, List<String>? groupIds) {
    if (groupIds == null) return;
    final id = stakeholder['id'] as String;
    for (final group in _groups) {
      final members = group['stakeholder_ids'] as List;
      if (groupIds.contains(group['id'])) {
        if (!members.contains(id)) members.add(id);
      } else {
        members.remove(id);
      }
    }
  }

  Json _requireLegacy(String id) =>
      _find(_legacies, id) ??
      (throw const MockApiError(404, 'legacy not found'));

  Json _requireAccount(String id) =>
      _find(_accounts, id) ??
      (throw const MockApiError(404, 'account not found'));

  Json _requireStakeholder(String id) =>
      _find(_stakeholders, id) ??
      (throw const MockApiError(404, 'stakeholder not found'));

  Json _requireGroup(String id) =>
      _find(_groups, id) ?? (throw const MockApiError(404, 'group not found'));

  Json _requireLastWord(String id) =>
      _find(_lastWords, id) ??
      (throw const MockApiError(404, 'last word not found'));

  Json _requireConfirmer(String id) =>
      _find(_confirmers, id) ??
      (throw const MockApiError(404, 'confirmer not found'));

  Json _requireConfirmerToken(Map<String, dynamic> headers) {
    final token = headers['X-Confirmer-Token'] as String? ?? '';
    final id = _confirmerTokens[token];
    if (id == null) throw const MockApiError(401, '확인자 인증이 필요해요.');
    final confirmer = _requireConfirmer(id);
    if (confirmer['status'] != 'accepted') {
      throw const MockApiError(403, '수락된 확인자가 아니에요.');
    }
    return confirmer;
  }

  Json _requireCase(String id, String ownerUserId) {
    final item = _find(_cases, id);
    if (item == null || item['user_id'] != ownerUserId) {
      throw const MockApiError(404, '전환 절차를 찾을 수 없어요.');
    }
    return item;
  }

  // ------------------------------------------------------------------ seed

  void _seed() {
    _user = {
      'id': _id('user'),
      'name': '김서연',
      'email': 'seoyeon.kim@gmail.com',
      'phone_number': '01012345678',
      'profile_image_path': null,
    };
    _config = {
      'id': _id('config'),
      'user_id': _user['id'],
      'lock_by_face_id': false,
      'certification_before_sensitive_information': true,
    };
    _policy = {
      'id': _id('policy'),
      'user_id': _user['id'],
      'minimum_confirmers': 2,
      'waiting_period_days': 14,
      'alive_check_interval_days': 90,
      'created_at': _now(),
      'updated_at': _now(),
    };

    String person(String name, String relationship, String email) {
      final stakeholder = <String, dynamic>{
        'id': _id('stakeholder'),
        'user_id': _user['id'],
        'name': name,
        'email': email,
        'phone': null,
        'relationship': relationship,
        'message': null,
        'created_at': _now(),
      };
      _stakeholders.add(stakeholder);
      return stakeholder['id'] as String;
    }

    final doyun = person('이도윤', '배우자', 'doyun.lee@example.com');
    final jeonghui = person('김정희', '어머니', 'jh.kim@example.com');
    final minjae = person('김민재', '형제', 'minjae.kim@example.com');
    final haeun = person('박하은', '친구', 'haeun.park@example.com');

    final familyId = _id('group');
    _groups.add({
      'id': familyId,
      'user_id': _user['id'],
      'name': '가족 그룹',
      'stakeholder_ids': [doyun, jeonghui, minjae],
      'created_at': _now(),
    });

    final legacyId = _id('legacy');
    _legacies.add({
      'id': legacyId,
      'user_id': _user['id'],
      'name': '내 데이터',
      'created_at': _now(),
    });

    void account({
      required String service,
      required String name,
      required String action,
      String? serviceName,
      String? message,
      String? accountId,
      String? password,
      String? dataLocation,
      List<String> stakeholderIds = const [],
      List<String> groupIds = const [],
    }) {
      _accounts.add({
        'id': _id('account'),
        'legacy_id': legacyId,
        'name': name,
        'type': {'id': _id('type'), 'type': service, 'name': serviceName},
        'action': {'id': _id('action'), 'action': action, 'message': message},
        'account_id': accountId,
        'account_password': password,
        'data_location': dataLocation,
        'stakeholder_ids': [...stakeholderIds],
        'stakeholder_group_ids': [...groupIds],
        'created_at': _now(),
      });
    }

    account(
      service: 'Google',
      name: '개인 계정',
      action: 'backup-and-delete',
      message: '가족사진 앨범을 백업한 뒤 계정을 삭제해 주세요. 업무 메일은 백업하지 않아도 괜찮아요.',
      accountId: 'seoyeon.kim@gmail.com',
      password: 'seoyeon-google',
      dataLocation: 'Google 포토 › 앨범 › 가족사진',
      stakeholderIds: [haeun],
      groupIds: [familyId],
    );
    account(
      service: 'Google',
      name: '학교 계정',
      action: 'delete',
      accountId: 'seoyeon@school.ac.kr',
      password: 'seoyeon-school',
      stakeholderIds: [doyun],
    );
    account(
      service: 'Instagram',
      name: '@seoyeon.daily',
      action: 'remain',
      message: '계정은 그대로 두고 추모 공간으로 남겨 주세요.',
      accountId: 'seoyeon.daily',
      password: 'seoyeon-insta',
      stakeholderIds: [doyun, haeun],
    );
    account(
      service: 'Other',
      serviceName: 'iCloud',
      name: '사진 보관함',
      action: 'permission-move',
      message: '사진 보관함 권한을 이도윤 님에게 넘겨 주세요.',
      accountId: 'seoyeon.kim@icloud.com',
      password: 'seoyeon-icloud',
      dataLocation: 'iCloud 사진 › 보관함',
      stakeholderIds: [doyun],
    );
    account(
      service: 'KakaoTalk',
      name: '개인 계정',
      action: 'backup-and-delete',
      accountId: 'seoyeon.kim',
      password: 'seoyeon-kakao',
    );

    _lastWords.add({
      'id': _id('last-word'),
      'user_id': _user['id'],
      'title': '가족에게',
      'message': '그동안 고마웠어요. 남은 일은 서로 의지하며 잘 지내길 바라요.',
      'receiver_ids': <String>[],
      'receiver_group_ids': [familyId],
    });

    _confirmers.addAll([
      {
        'id': _id('confirmer'),
        'user_id': _user['id'],
        'stakeholder_id': doyun,
        'name': '이도윤',
        'email': 'doyun.lee@example.com',
        'status': 'accepted',
        'invited_at': _now(),
        'accepted_at': _now(),
        'created_at': _now(),
        'updated_at': _now(),
      },
      {
        'id': _id('confirmer'),
        'user_id': _user['id'],
        'stakeholder_id': jeonghui,
        'name': '김정희',
        'email': 'jh.kim@example.com',
        'status': 'pending',
        'invited_at': _now(),
        'invite_expires_at': _daysFromNow(7),
        'created_at': _now(),
        'updated_at': _now(),
      },
    ]);
  }
}
