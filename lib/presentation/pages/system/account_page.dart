import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/providers/auth_providers.dart';
import 'package:flutterbase/presentation/theme/theme.dart';
import 'package:flutterbase/presentation/widgets/ui/widgets.dart';

/// The optional sign-in: who is signed in, and the button to sign in or out.
///
/// Only reachable when the build carries the sign-in settings — the drawer
/// entry is hidden otherwise (docs/adr/0007-optional-assay-sign-in.md).
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AppError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).accountSignInFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppMainHeader(title: l10n.accountTitle),
      body: switch (ref.watch(accountProvider)) {
        AsyncLoading<Account?>() => const AppLoadingView(),
        AsyncError<Account?>(:final error) => AppErrorView(
          message: error is AppError ? error.message : l10n.commonError,
          onRetry: () => ref.invalidate(accountProvider),
        ),
        AsyncData<Account?>(:final value) => _buildContent(context, value),
      },
    );
  }

  Widget _buildContent(BuildContext context, Account? account) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(accountProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      children: [
        AppCard(
          child: account == null
              ? Text(l10n.accountNotSignedIn)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountSignedInLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      account.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (account.email != null) Text(account.email!),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (account == null)
          AppPrimaryButton(
            label: l10n.accountSignIn,
            isLoading: _busy,
            onPressed: _busy ? null : () => _run(notifier.signIn),
          )
        else
          AppSecondaryButton(
            label: l10n.accountSignOut,
            onPressed: _busy ? null : () => _run(notifier.signOut),
          ),
      ],
    );
  }
}
