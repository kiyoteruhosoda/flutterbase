import 'package:flutter/material.dart';
import 'package:flutterbase/presentation/widgets/ui/app_license_launcher.dart';
import 'package:flutterbase/shared/l10n/app_localizations.dart';
import 'package:flutterbase/shared/theme/theme.dart';

/// Footer bar shown at the bottom of the main screen.
/// Contains navigation links only — version info is on the About page.
class AppMainFooter extends StatelessWidget {
  const AppMainFooter({
    super.key,
    this.links,
  });

  final List<AppFooterLink>? links;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (links == null || links!.isEmpty) return const SizedBox.shrink();
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageMargin,
            vertical: AppSpacing.sm,
          ),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: links!
                .map(
                  (link) => InkWell(
                    onTap: link.onTap,
                    child: Text(
                      link.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class AppFooterLink {
  const AppFooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
}

/// Convenience: default footer with About and Licenses links.
class AppDefaultFooter extends StatelessWidget {
  const AppDefaultFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppMainFooter(
      links: [
        AppFooterLink(
          label: l10n.footerAbout,
          onTap: () => Navigator.of(context).pushNamed('/about'),
        ),
        AppFooterLink(
          label: l10n.footerLicenses,
          onTap: () => openAppLicensePage(context),
        ),
      ],
    );
  }
}
