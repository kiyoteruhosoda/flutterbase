import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/usecases/auth/get_current_account_usecase.dart';
import 'package:flutterbase/application/usecases/auth/sign_in_usecase.dart';
import 'package:flutterbase/application/usecases/auth/sign_out_usecase.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';
import 'package:flutterbase/presentation/providers/push_providers.dart';

// ─── Settings ──────────────────────────────────────────────────────────────

/// Whether this build has the optional sign-in, and where it goes.
///
/// Defaults to "off" rather than throwing like the use-case seams: a screen
/// that merely asks "is there a sign-in?" must work in every widget test and
/// in a build without the `--dart-define`s. The composition root overrides it
/// with what the build carries.
final Provider<SignInSettings> signInSettingsProvider =
    Provider<SignInSettings>((ref) => const SignInSettings.disabled());

// ─── Use-case seams ────────────────────────────────────────────────────────
//
// Overridden only when the sign-in is on. Nothing reads them otherwise: the
// menu entry that leads to the account screen is hidden.

final Provider<GetCurrentAccountUseCase> getCurrentAccountUseCaseProvider =
    Provider<GetCurrentAccountUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('getCurrentAccountUseCaseProvider'),
      );
    });

final Provider<SignInUseCase> signInUseCaseProvider = Provider<SignInUseCase>((
  ref,
) {
  throw UnimplementedError(missingOverrideMessage('signInUseCaseProvider'));
});

final Provider<SignOutUseCase> signOutUseCaseProvider =
    Provider<SignOutUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('signOutUseCaseProvider'),
      );
    });

// ─── Screen state ──────────────────────────────────────────────────────────

/// Who is signed in on this device (null when nobody is).
final AsyncNotifierProvider<AccountNotifier, Account?> accountProvider =
    AsyncNotifierProvider<AccountNotifier, Account?>(
      AccountNotifier.new,
      retry: (retryCount, error) => null,
    );

/// Loads the signed-in account and signs in or out on request.
///
/// A failed sign-in leaves the previous state in place and rethrows, so the
/// screen can report it without losing what it was showing.
class AccountNotifier extends AsyncNotifier<Account?> {
  @override
  Future<Account?> build() =>
      ref.read(getCurrentAccountUseCaseProvider).execute();

  /// Opens the identity provider's page. Returns false when the person backed
  /// out (nothing changes).
  Future<bool> signIn() async {
    final account = await ref.read(signInUseCaseProvider).execute();
    if (account == null) return false;
    state = AsyncData(account);
    return true;
  }

  Future<void> signOut() async {
    // Before the sign-out: taking the device off the list needs the person's
    // token (docs/adr/0010-notifications-through-fcm.md). Never throws.
    await ref.read(pushRegistrationProvider.notifier).unregister();
    await ref.read(signOutUseCaseProvider).execute();
    state = const AsyncData(null);
  }
}
