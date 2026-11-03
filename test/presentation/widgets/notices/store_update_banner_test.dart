import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/ports/store_update_gateway.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/entities/app_notice.dart';
import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/presentation/l10n/app_localizations_en.dart';
import 'package:flutterbase/presentation/l10n/app_localizations_ja.dart';
import 'package:flutterbase/presentation/pages/main_page.dart';
import 'package:flutterbase/presentation/providers/store_update_providers.dart';

import '../../../support/fakes.dart';
import '../../../support/test_harness.dart';

/// The banner for a newer build on Google Play
/// (docs/adr/0012-offer-updates-through-google-play.md), as the main screen
/// shows it.

const l10n = AppLocalizationsEn();

/// The background and back again, one legal step at a time.
const List<AppLifecycleState> lifecycleRoundTrip = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

/// Sends the app to the background and back.
Future<void> leaveAndReturn(WidgetTester tester) async {
  for (final state in lifecycleRoundTrip) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

TestScope playScope(StoreUpdateStatus status) =>
    TestScope()..storeUpdates.status = status;

void main() {
  group('when it asks Play', () {
    testWidgets('on start, without a sign-in', (tester) async {
      final scope = playScope(StoreUpdateStatus.available);
      await pumpInScope(tester, const MainPage(), scope: scope);

      expect(scope.storeUpdates.checks, 1);
      expect(find.text(l10n.storeUpdateAvailable), findsOneWidget);
    });

    testWidgets('again on every return to the front', (tester) async {
      final scope = TestScope();
      await pumpInScope(tester, const MainPage(), scope: scope);
      expect(find.byType(MaterialBanner), findsNothing);

      // A build went out on Play while the app was in the background.
      scope.storeUpdates.status = StoreUpdateStatus.available;
      await leaveAndReturn(tester);

      expect(scope.storeUpdates.checks, 2);
      expect(find.text(l10n.storeUpdateAvailable), findsOneWidget);

      await leaveAndReturn(tester);
      expect(scope.storeUpdates.checks, 3);
    });
  });

  group('the flow', () {
    testWidgets('update downloads in the background, then restart installs', (
      tester,
    ) async {
      final scope = playScope(StoreUpdateStatus.available);
      final pending = scope.storeUpdates.pendingDownload = Completer<bool>();
      await pumpInScope(tester, const MainPage(), scope: scope);

      await tester.tap(find.text(l10n.storeUpdateDownload));
      await tester.pump();
      expect(scope.storeUpdates.downloads, 1);
      expect(find.text(l10n.storeUpdateDownloading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(l10n.storeUpdateDownload), findsNothing);

      // Coming back mid-download does not take the banner back a step.
      scope.storeUpdates.status = StoreUpdateStatus.available;
      for (final state in lifecycleRoundTrip) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(scope.storeUpdates.checks, 1);
      expect(find.text(l10n.storeUpdateDownloading), findsOneWidget);

      pending.complete(true);
      await tester.pumpAndSettle();
      expect(find.text(l10n.storeUpdateDownloaded), findsOneWidget);

      await tester.tap(find.text(l10n.storeUpdateInstall));
      await tester.pumpAndSettle();
      expect(scope.storeUpdates.installs, 1);
    });

    testWidgets('declining Play prompt offers the update again', (
      tester,
    ) async {
      final scope = playScope(StoreUpdateStatus.available)
        ..storeUpdates.downloadSucceeds = false;
      await pumpInScope(tester, const MainPage(), scope: scope);

      await tester.tap(find.text(l10n.storeUpdateDownload));
      await tester.pumpAndSettle();

      expect(scope.storeUpdates.downloads, 1);
      expect(find.text(l10n.storeUpdateAvailable), findsOneWidget);
      expect(find.text(l10n.storeUpdateDownload), findsOneWidget);
    });

    testWidgets('a build downloaded earlier goes straight to restart', (
      tester,
    ) async {
      final scope = playScope(StoreUpdateStatus.downloaded);
      await pumpInScope(tester, const MainPage(), scope: scope);

      expect(find.text(l10n.storeUpdateDownloaded), findsOneWidget);
      await tester.tap(find.text(l10n.storeUpdateInstall));
      await tester.pumpAndSettle();
      expect(scope.storeUpdates.installs, 1);
      expect(scope.storeUpdates.downloads, 0);
    });

    testWidgets('has no way to put it away', (tester) async {
      await pumpInScope(
        tester,
        const MainPage(),
        scope: playScope(StoreUpdateStatus.available),
      );
      expect(find.text(l10n.commonClose), findsNothing);
    });
  });

  group('stays quiet', () {
    testWidgets('for a copy Play did not install', (tester) async {
      // The fake answers none, as the real gateway does for an APK from
      // share.nolumia.com, a local build, or a Play that cannot be asked.
      final scope = TestScope();
      await pumpInScope(tester, const MainPage(), scope: scope);

      expect(scope.storeUpdates.checks, 1);
      expect(find.byType(MaterialBanner), findsNothing);
    });

    testWidgets('once Play has nothing more to offer', (tester) async {
      final scope = playScope(StoreUpdateStatus.available);
      await pumpInScope(tester, const MainPage(), scope: scope);
      expect(find.byType(MaterialBanner), findsOneWidget);

      scope.storeUpdates.status = StoreUpdateStatus.none;
      await leaveAndReturn(tester);
      expect(find.byType(MaterialBanner), findsNothing);
    });
  });

  group('next to the paired web app', () {
    const kyon = Account(displayName: 'Kyon');
    final webRelease = AppRelease(
      version: '1.43.0',
      build: 43, // testAppInfo is build 42
      downloadUrl: Uri.parse('https://share.example.com/app.apk'),
    );
    final notice = testNotice(
      id: 2,
      title: 'Planned maintenance',
      body: 'Tonight at 23:00',
      channels: {NoticeChannel.banner},
    );

    TestScope signedInScope(StoreUpdateStatus status) => TestScope(
      authSession: FakeAuthSession(signedIn: kyon),
      appReleaseRepository: FakeAppReleaseRepository(webRelease),
      noticeRepository: FakeAppNoticeRepository(
        AppNoticeInbox(items: [notice], unreadCount: 0),
      ),
    )..storeUpdates.status = status;

    testWidgets('Play wins: only one banner shows', (tester) async {
      await pumpInScope(
        tester,
        const MainPage(),
        scope: signedInScope(StoreUpdateStatus.available),
      );

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text(l10n.storeUpdateAvailable), findsOneWidget);
      expect(find.text(l10n.updateAvailable('1.43.0')), findsNothing);
      expect(find.text('Planned maintenance'), findsNothing);
    });

    testWidgets('without Play, the web app banner is as before', (
      tester,
    ) async {
      await pumpInScope(
        tester,
        const MainPage(),
        scope: signedInScope(StoreUpdateStatus.none),
      );

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text(l10n.updateAvailable('1.43.0')), findsOneWidget);
    });
  });

  testWidgets('fits in Japanese on a phone-sized screen', (tester) async {
    const ja = AppLocalizationsJa();
    final scope = playScope(StoreUpdateStatus.downloaded);
    await pumpInScope(
      tester,
      const MainPage(),
      scope: scope,
      locale: const Locale('ja'),
      surfaceSize: const Size(360, 740),
    );

    expect(find.text(ja.storeUpdateDownloaded), findsOneWidget);
    expect(find.text(ja.storeUpdateInstall), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      scope.container.read(storeUpdateProvider),
      StoreUpdateStage.downloaded,
    );
  });
}
