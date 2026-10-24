# diealog_app

DIEALOG mobile app (Flutter).

## Run

```sh
flutter pub get
flutter run                                   # https://diealog.shxin.kr/api
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api
flutter test
```

## Layout

```
lib/
  core/        config, network (Dio + auth interceptor), token storage, router
  data/        models, repositories, providers.dart (Riverpod wiring)
    repositories/mock/   features the backend does not expose yet
  features/    screens, one folder per feature
```

Backend API: https://diealog.shxin.kr/swagger/index.html

Mocked until the backend adds them: email verification / OTP, profile and
password editing, user deletion, and the whole after-death side (entrusted
records, received messages). Swap the implementation in `data/providers.dart`
when the endpoints exist.
