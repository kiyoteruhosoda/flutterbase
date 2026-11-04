import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/infrastructure/push/fid_registrations.dart';

void main() {
  late StreamController<String> registered;
  late int registerCalls;
  late String? answer;
  late FidRegistrations fids;

  setUp(() {
    registered = StreamController<String>.broadcast();
    registerCalls = 0;
    answer = 'fid-1';
    fids = FidRegistrations(registered.stream, () async {
      registerCalls++;
      final fid = answer;
      // FCM answers on the stream after register() returns.
      if (fid != null) scheduleMicrotask(() => registered.add(fid));
    }, timeout: const Duration(milliseconds: 50));
  });

  tearDown(() async {
    await fids.close();
    await registered.close();
  });

  test('registers and answers the FID FCM emits', () async {
    expect(await fids.current(), 'fid-1');
    expect(registerCalls, 1);
  });

  test('the answer to a register() is not reported as a change', () async {
    final changes = <String>[];
    final subscription = fids.changes.listen(changes.add);
    await fids.current();
    await fids.current();
    await pumpEventQueue();
    expect(changes, isEmpty);
    await subscription.cancel();
  });

  test(
    'a new FID FCM emits by itself is a change; the same one is not',
    () async {
      await fids.current();
      final changes = <String>[];
      final subscription = fids.changes.listen(changes.add);
      registered
        ..add('fid-1')
        ..add('fid-2')
        ..add('fid-2');
      await pumpEventQueue();
      expect(changes, ['fid-2']);
      answer = 'fid-2';
      expect(await fids.current(), 'fid-2');
      await subscription.cancel();
    },
  );

  test('answers the last FID heard when FCM does not answer in time', () async {
    expect(await fids.current(), 'fid-1');
    answer = null;
    expect(await fids.current(), 'fid-1');
  });

  test('answers null when FCM never answered', () async {
    answer = null;
    expect(await fids.current(), isNull);
  });

  test('a failing register() reaches the caller', () async {
    final failing = FidRegistrations(
      registered.stream,
      () async => throw StateError('flag not set'),
    );
    await expectLater(failing.current(), throwsStateError);
    await failing.close();
  });
}
