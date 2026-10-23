import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/entities/service_outage.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/infrastructure/api/web_api_client.dart';
import 'package:flutterbase/presentation/l10n/app_localizations_en.dart';
import 'package:flutterbase/presentation/l10n/app_localizations_ja.dart';
import 'package:flutterbase/presentation/providers/service_status_providers.dart';
import 'package:flutterbase/presentation/widgets/maintenance/maintenance_view.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/fakes.dart';
import '../../../support/test_harness.dart';

// The in-app maintenance screen (task #665, docs/adr/0011-*). The edge is
// played at the wire: a real WebApiClient over a MockClient, so these tests
// read the same JSON the edge sends.

const en = AppLocalizationsEn();
const ja = AppLocalizationsJa();

/// What the screen under the maintenance screen shows.
const String originalScreen = 'original screen';

final DateTime until = DateTime.utc(2026, 10, 28, 19, 30);

/// The edge while a maintenance is declared, with #663's title and body.
Map<String, Object?> maintenanceJson() => <String, Object?>{
  'error': 'service_unavailable',
  'reason': 'maintenance',
  'until': '2026-10-28T19:30:00Z',
  'message': 'Rebuilding the database',
  'title': 'Scheduled maintenance',
  'body': 'We are moving to a new database.',
};

/// A paired web app behind an edge whose answer the test can change.
final class FakeEdge {
  /// What every request gets while set; null lets them through.
  Map<String, Object?>? closedWith = maintenanceJson();

  /// What a request gets when the edge is open.
  http.Response Function() open = () => http.Response('{}', 200);

  final List<http.Request> requests = <http.Request>[];

  late final WebApiClient api = WebApiClient(
    FakeAuthSession(signedIn: const Account(displayName: 'Kyon')),
    TestScope.enabledSignIn.webBaseUrl,
    httpClient: MockClient((request) async {
      requests.add(request);
      final closed = closedWith;
      if (closed == null) return open();
      return http.Response.bytes(
        utf8.encode(jsonEncode(closed)),
        503,
        headers: {'content-type': 'application/json'},
      );
    }),
  );

  /// The checks the maintenance screen made.
  int get checks =>
      requests.where((r) => r.url.path == WebApiClient.checkPath).length;
}

Future<TestScope> pumpApp(
  WidgetTester tester,
  FakeEdge edge, {
  Locale? locale,
}) {
  return pumpInScope(
    tester,
    const Scaffold(body: TextField(key: Key('draft'))),
    locale: locale,
    scope: TestScope(
      authSession: FakeAuthSession(signedIn: const Account(displayName: 'K')),
      serviceStatus: edge.api,
    ),
  ).then((scope) async {
    await tester.enterText(find.byKey(const Key('draft')), originalScreen);
    return scope;
  });
}

/// Any screen calling the web app — here the notices — meets the edge.
Future<void> callTheWebApp(FakeEdge edge, WidgetTester tester) async {
  try {
    await edge.api.getJson('/api/notifications');
  } on AppError {
    // The screen that made the call handles its own failure as before.
  }
  await tester.pump();
}

void main() {
  testWidgets('AC1: maintenance shows title, body, reason and the local '
      'time it is expected back', (tester) async {
    final edge = FakeEdge();
    await pumpApp(tester, edge);
    expect(find.text(originalScreen), findsOneWidget);

    await callTheWebApp(edge, tester);

    expect(find.byType(MaintenanceView), findsOneWidget);
    expect(find.text('Scheduled maintenance'), findsOneWidget);
    expect(find.text('We are moving to a new database.'), findsOneWidget);
    expect(
      find.text(en.maintenanceReason('Rebuilding the database')),
      findsOneWidget,
    );

    final context = tester.element(find.byType(MaintenanceView));
    final shown = formatLocalInstant(context, until);
    expect(find.text(en.maintenanceUntil(shown)), findsOneWidget);
    // In the device's time zone, not the edge's UTC.
    final local = until.toLocal();
    expect(
      shown,
      contains(
        MaterialLocalizations.of(context)
            .formatTimeOfDay(TimeOfDay.fromDateTime(local)),
      ),
    );
    expect(
      shown,
      contains(MaterialLocalizations.of(context).formatMediumDate(local)),
    );

    // The screen underneath is hidden, not thrown away.
    expect(find.text(originalScreen), findsNothing);
    expect(find.text(originalScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('AC2: a recheck that gets through takes the person back', (
    tester,
  ) async {
    final edge = FakeEdge();
    await pumpApp(tester, edge);
    await callTheWebApp(edge, tester);
    expect(find.byType(MaintenanceView), findsOneWidget);

    // Still closed at the first recheck: the screen stays.
    await tester.pump(ServiceOutageNotifier.recheckInterval);
    await tester.pump();
    expect(edge.checks, 1);
    expect(find.byType(MaintenanceView), findsOneWidget);

    // Opened: the next recheck takes the screen away.
    edge.closedWith = null;
    await tester.pump(
      ServiceOutageNotifier.recheckInterval - const Duration(seconds: 1),
    );
    expect(edge.checks, 1);
    expect(find.byType(MaintenanceView), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(edge.checks, 2);
    expect(find.byType(MaintenanceView), findsNothing);
    // Back where they were, with what they had typed.
    expect(find.text(originalScreen), findsOneWidget);

    // No more checks once in service.
    await tester.pump(ServiceOutageNotifier.recheckInterval * 3);
    expect(edge.checks, 2);
  });

  testWidgets('AC2: "Check now" asks without waiting for the timer', (
    tester,
  ) async {
    final edge = FakeEdge();
    await pumpApp(tester, edge);
    await callTheWebApp(edge, tester);

    edge
      ..closedWith = null
      ..open = () => http.Response('', 401); // any answer means "back"
    await tester.tap(find.text(en.maintenanceCheckNow));
    await tester.pump();
    await tester.pump();

    expect(edge.checks, 1);
    expect(find.byType(MaintenanceView), findsNothing);
    expect(find.text(originalScreen), findsOneWidget);
  });

  testWidgets('a recheck without network keeps the screen', (tester) async {
    final status = FakeServiceStatus();
    await pumpInScope(
      tester,
      const Text(originalScreen),
      scope: TestScope(authSession: FakeAuthSession(), serviceStatus: status),
    );
    status.outageController.add(
      const ServiceOutage(reason: ServiceOutageReason.maintenance),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(MaintenanceView), findsOneWidget);

    status.checkFailure = const InfrastructureError('offline');
    await tester.pump(ServiceOutageNotifier.recheckInterval);
    await tester.pump();
    expect(status.checks, 1);
    expect(find.byType(MaintenanceView), findsOneWidget);

    status.checkFailure = null;
    await tester.pump(ServiceOutageNotifier.recheckInterval);
    await tester.pump();
    expect(status.checks, 2);
    expect(find.byType(MaintenanceView), findsNothing);
  });

  testWidgets('AC3: stopped shows the stopped wording', (tester) async {
    final edge = FakeEdge()
      ..closedWith = <String, Object?>{
        'error': 'service_unavailable',
        'reason': 'stopped',
        'host': 'web.example.com',
      };
    await pumpApp(tester, edge, locale: const Locale('ja'));
    await callTheWebApp(edge, tester);

    expect(find.text(ja.serviceStoppedTitle), findsOneWidget);
    expect(find.text(ja.serviceStoppedBody), findsOneWidget);
    expect(find.text(ja.maintenanceTitle), findsNothing);
    expect(find.textContaining('理由'), findsNothing);
    expect(find.textContaining('戻りの見込み'), findsNothing);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });

  testWidgets('AC3: maintenance JSON without title/body uses the default '
      'wording', (tester) async {
    final edge = FakeEdge()
      ..closedWith = <String, Object?>{
        'error': 'service_unavailable',
        'reason': 'maintenance',
        'until': '2026-10-28T19:30:00Z',
        'message': 'DB の作り直し',
      };
    await pumpApp(tester, edge, locale: const Locale('ja'));
    await callTheWebApp(edge, tester);

    expect(find.text(ja.maintenanceTitle), findsOneWidget);
    expect(find.text(ja.maintenanceBody), findsOneWidget);
    expect(find.text(ja.maintenanceReason('DB の作り直し')), findsOneWidget);
    expect(find.textContaining('戻りの見込み'), findsOneWidget);
    expect(find.byIcon(Icons.construction), findsOneWidget);
  });

  group('AC4: other failures are handled as before', () {
    for (final (name, response) in <(String, http.Response Function())>[
      ('a 503 that is not JSON', () => http.Response('<html>', 503)),
      ('a 503 with another JSON', () => http.Response('{"x":1}', 503)),
      ('a 500', () => http.Response('{}', 500)),
    ]) {
      testWidgets('$name stays on the screen', (tester) async {
        final edge = FakeEdge()
          ..closedWith = null
          ..open = response;
        await pumpApp(tester, edge);

        await expectLater(
          edge.api.getJson('/api/notifications'),
          throwsA(isA<InfrastructureError>()),
        );
        await tester.pump();

        expect(find.byType(MaintenanceView), findsNothing);
        expect(find.text(originalScreen), findsOneWidget);
      });
    }
  });

  testWidgets('without the sign-in there is nothing to watch', (tester) async {
    await pumpInScope(tester, const Text(originalScreen));
    expect(find.text(originalScreen), findsOneWidget);
    expect(find.byType(MaintenanceView), findsNothing);
  });
}
