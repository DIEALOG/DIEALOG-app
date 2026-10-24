import 'package:diealog_app/features/auth/signup/signup_rules.dart';
import 'package:diealog_app/features/home/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignupRules', () {
    test('accepts a name that is not blank', () {
      expect(SignupRules.nameOk('김서연'), isTrue);
      expect(SignupRules.nameOk('  '), isFalse);
    });

    test('checks email shape', () {
      expect(SignupRules.emailOk('name@example.com'), isTrue);
      expect(SignupRules.emailOk('name@'), isFalse);
    });

    test('requires 8+ chars with a letter and a digit', () {
      expect(SignupRules.passwordOk('secret12'), isTrue);
      expect(SignupRules.passwordLongEnough('short1'), isFalse);
      expect(SignupRules.passwordHasLetterAndDigit('abcdefgh'), isFalse);
      expect(SignupRules.passwordHasLetterAndDigit('12345678'), isFalse);
    });

    test('formats a Korean mobile number', () {
      expect(SignupRules.formatPhone('01074722414'), '010-7472-2414');
      expect(SignupRules.phoneOk('010-7472-2414'), isTrue);
      expect(SignupRules.phoneOk('010-123'), isFalse);
    });
  });

  group('greetingFor', () {
    test('splits the day into morning, afternoon, evening', () {
      expect(greetingFor(DateTime(2026, 10, 24, 9)), '좋은 아침이에요');
      expect(greetingFor(DateTime(2026, 10, 24, 15)), '좋은 오후예요');
      expect(greetingFor(DateTime(2026, 10, 24, 20)), '좋은 저녁이에요');
    });

    test('takes the first character of a name', () {
      expect(firstCharacter('김서연'), '김');
      expect(firstCharacter(''), '');
    });
  });
}
