import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/domain/entities/service_outage.dart';
import 'package:flutterbase/presentation/providers/service_status_providers.dart';
import 'package:flutterbase/presentation/widgets/maintenance/maintenance_view.dart';

/// Puts the [MaintenanceView] over the whole app while the paired web app is
/// out of service (docs/adr/0011-in-app-maintenance-screen.md).
///
/// Installed as `MaterialApp.router`'s `builder`, so [child] is the router's
/// navigator. It stays mounted, only hidden, while the maintenance screen is
/// up: when the service is back the person is where they were, with what they
/// had typed.
///
/// The recheck timer lives here rather than in the notifier: it runs only
/// while the screen is shown, and goes away with it.
class ServiceOutageGate extends ConsumerStatefulWidget {
  const ServiceOutageGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ServiceOutageGate> createState() => _ServiceOutageGateState();
}

class _ServiceOutageGateState extends ConsumerState<ServiceOutageGate> {
  Timer? _recheck;

  @override
  void initState() {
    super.initState();
    ref.listenManual<ServiceOutage?>(
      serviceOutageProvider,
      (_, outage) => _follow(outage),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _recheck?.cancel();
    super.dispose();
  }

  void _follow(ServiceOutage? outage) {
    if (outage == null) {
      _recheck?.cancel();
      _recheck = null;
      return;
    }
    _recheck ??= Timer.periodic(
      ServiceOutageNotifier.recheckInterval,
      (_) => unawaited(_checkNow()),
    );
  }

  Future<void> _checkNow() =>
      ref.read(serviceOutageProvider.notifier).recheck();

  @override
  Widget build(BuildContext context) {
    final outage = ref.watch(serviceOutageProvider);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Offstage(
          offstage: outage != null,
          child: TickerMode(enabled: outage == null, child: widget.child),
        ),
        if (outage != null) MaintenanceView(outage: outage, onCheck: _checkNow),
      ],
    );
  }
}
