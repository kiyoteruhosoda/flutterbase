import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/usecases/auth/get_current_account_usecase.dart';
import 'package:flutterbase/application/usecases/auth/sign_in_usecase.dart';
import 'package:flutterbase/application/usecases/auth/sign_out_usecase.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/errors/app_error.dart';

import '../../../support/fakes.dart';
import '../../../support/recording_app_logger.dart';

void main() {
  late FakeAuthSession session;
  late RecordingAppLogger logger;

  setUp(() {
    session = FakeAuthSession();
    logger = RecordingAppLogger();
  });

  test('GetCurrentAccountUseCase reads who is signed in', () async {
    expect(await GetCurrentAccountUseCase(session).execute(), isNull);
    session.signedIn = const Account(displayName: 'Kyon');
    expect(
      await GetCurrentAccountUseCase(session).execute(),
      const Account(displayName: 'Kyon'),
    );
  });

  test('SignInUseCase returns the account', () async {
    final account = await SignInUseCase(session, logger).execute();
    expect(account, session.account);
  });

  test(
    'SignInUseCase treats backing out as "no account", not a failure',
    () async {
      session.signInFailure = SignInCancelledError('closed'.toString());
      expect(await SignInUseCase(session, logger).execute(), isNull);
    },
  );

  test('SignInUseCase lets real failures through', () async {
    session.signInFailure = InfrastructureError('offline'.toString());
    await expectLater(
      SignInUseCase(session, logger).execute(),
      throwsA(isA<InfrastructureError>()),
    );
  });

  test('SignOutUseCase forgets the sign-in', () async {
    session.signedIn = const Account(displayName: 'Kyon');
    await SignOutUseCase(session, logger).execute();
    expect(session.signOuts, 1);
    expect(session.signedIn, isNull);
  });
}
