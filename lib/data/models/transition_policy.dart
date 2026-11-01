import 'json.dart';

/// `domain.UserTransitionPolicy`: when a death report turns into disclosure.
class TransitionPolicy {
  const TransitionPolicy({
    this.aliveCheckIntervalDays = 90,
    this.minimumConfirmers = 2,
    this.waitingPeriodDays = 7,
  });

  factory TransitionPolicy.fromJson(Json json) => TransitionPolicy(
    aliveCheckIntervalDays: json['alive_check_interval_days'] as int? ?? 90,
    minimumConfirmers: json['minimum_confirmers'] as int? ?? 2,
    waitingPeriodDays: json['waiting_period_days'] as int? ?? 7,
  );

  /// How often the server asks whether the owner is still alive.
  final int aliveCheckIntervalDays;

  /// Accepted confirmers who must agree before the waiting period starts.
  final int minimumConfirmers;

  /// Extra delay after the confirmers agree.
  final int waitingPeriodDays;

  /// Intervals offered in the 생존 확인 주기 sheet.
  static const intervalChoices = [30, 60, 90, 180];
  static const defaultInterval = 90;

  String get summary => '확인자 $minimumConfirmers명 동의 + $waitingPeriodDays일 대기';

  /// Body for `PATCH /transition/protected/policy`.
  Json toJson() => {
    'alive_check_interval_days': aliveCheckIntervalDays,
    'minimum_confirmers': minimumConfirmers,
    'waiting_period_days': waitingPeriodDays,
  };
}
