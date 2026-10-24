import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupDraft {
  const SignupDraft({
    this.name = '',
    this.email = '',
    this.password = '',
    this.phone = '',
  });

  final String name;
  final String email;
  final String password;
  final String phone;

  SignupDraft copyWith({
    String? name,
    String? email,
    String? password,
    String? phone,
  }) =>
      SignupDraft(
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        phone: phone ?? this.phone,
      );
}

final signupDraftProvider =
    NotifierProvider<SignupDraftNotifier, SignupDraft>(SignupDraftNotifier.new);

class SignupDraftNotifier extends Notifier<SignupDraft> {
  @override
  SignupDraft build() => const SignupDraft();

  void setName(String value) => state = state.copyWith(name: value.trim());

  void setEmail(String value) =>
      state = state.copyWith(email: value.trim());

  void setPassword(String value) => state = state.copyWith(password: value);

  void setPhone(String value) => state = state.copyWith(phone: value);

  void clear() => state = const SignupDraft();
}
