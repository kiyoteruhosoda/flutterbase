import 'package:flutter/material.dart';
import 'package:flutterbase/domain/entities/service_outage.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/theme/theme.dart';

/// The in-app maintenance screen (docs/adr/0011-in-app-maintenance-screen.md).
///
/// Shows what the edge sent — heading, text, reason, when the service is
/// expected back — and falls back to the app's own wording for whatever it
/// left out. [ServiceOutage.until] is shown in the device's time zone.
class MaintenanceView extends StatelessWidget {
  const MaintenanceView({
    super.key,
    required this.outage,
    required this.onCheck,
  });

  final ServiceOutage outage;

  /// Asks the server now instead of waiting for the next recheck.
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final maintenance = outage.reason == ServiceOutageReason.maintenance;
    final message = outage.message;
    final until = outage.until;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  maintenance ? Icons.construction : Icons.cloud_off,
                  size: AppSpacing.minTapTarget,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  outage.title ??
                      (maintenance
                          ? l10n.maintenanceTitle
                          : l10n.serviceStoppedTitle),
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  outage.body ??
                      (maintenance
                          ? l10n.maintenanceBody
                          : l10n.serviceStoppedBody),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.maintenanceReason(message),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (until != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.maintenanceUntil(formatLocalInstant(context, until)),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.maintenanceAutoCheck,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: onCheck,
                  child: Text(l10n.maintenanceCheckNow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [instant] as a date and time in the device's time zone, in the app's
/// language.
String formatLocalInstant(BuildContext context, DateTime instant) {
  final local = instant.toLocal();
  final material = MaterialLocalizations.of(context);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '${material.formatMediumDate(local)} $time';
}
