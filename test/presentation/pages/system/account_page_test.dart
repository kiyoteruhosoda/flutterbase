import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/presentation/l10n/app_localizations_en.dart';
import 'package:flutterbase/presentation/pages/system/account_page.dart';

import '../../../support/fakes.dart';
import '../../../support/test_harness.dart';

const l10n = AppLocalizationsEn();

void main() {
  group('AccountPage', () {
    testWidgets('offers the sign-in when nobody is signed in', (tester) async {
      await pumpInScope(
        tester,
        const AccountPage(),
        scope: TestScope(authSession: FakeAuthSession()),
      );
      expect(find.text(l10n.accountNotSignedIn), findsOneWidget);
      expect(find.text(l10n.accountSignIn), findsOneWidget);
      expect(find.text(l10n.accountSignOut), findsNothing);
    });

    testWidgets('signs in and shows who', (tester) async {
      final session = FakeAuthSession();
      await pumpInScope(
        tester,
        const AccountPage(),
        scope: TestScope(authSession: session),
      );
      await tester.tap(find.text(l10n.accountSignIn));
      await tester.pumpAndSettle();
      expect(find.text('Kyon'), findsOneWidget);
      expect(find.text('kyon@example.com'), findsOneWidget);
      expect(find.text(l10n.accountSignOut), findsOneWidget);
    });

    testWidgets('backing out of the sign-in changes nothing', (tester) async {
      final session = FakeAuthSession()
        ..signInFailure = SignInCancelledError('closed'.toString());
      await pumpInScope(
        tester,
        const AccountPage(),
        scope: TestScope(authSession: session),
      );
      await tester.tap(find.text(l10n.accountSignIn));
      await tester.pumpAndSettle();
      expect(find.text(l10n.accountNotSignedIn), findsOneWidget);
      expect(find.text(l10n.accountSignInFailed), findsNothing);
    });

    testWidgets('a failed sign-in is reported', (tester) async {
      final session = FakeAuthSession()
        ..signInFailure = InfrastructureError('offline'.toString());
      await pumpInScope(
        tester,
        const AccountPage(),
        scope: TestScope(authSession: session),
      );
      await tester.tap(find.text(l10n.accountSignIn));
      await tester.pumpAndSettle();
      expect(find.text(l10n.accountSignInFailed), findsOneWidget);
      expect(find.text(l10n.accountNotSignedIn), findsOneWidget);
    });

    testWidgets('signs out', (tester) async {
      final session = FakeAuthSession(
        signedIn: const Account(displayName: 'Kyon'),
      );
      await pumpInScope(
        tester,
        const AccountPage(),
        scope: TestScope(authSession: session),
      );
      expect(find.text('Kyon'), findsOneWidget);
      await tester.tap(find.text(l10n.accountSignOut));
      await tester.pumpAndSettle();
      expect(session.signOuts, 1);
      expect(find.text(l10n.accountNotSignedIn), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
