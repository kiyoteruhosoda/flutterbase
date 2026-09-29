// `Override` — the type `ProviderScope.overrides` takes — lives in Riverpod's
// `misc.dart` rather than its main entry point.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutterbase/app/di/service_locator.dart';
import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/application/usecases/app_info/get_app_info_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/check_for_update_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/dismiss_update_usecase.dart';
import 'package:flutterbase/application/usecases/app_update/open_update_download_usecase.dart';
import 'package:flutterbase/application/usecases/auth/get_current_account_usecase.dart';
import 'package:flutterbase/application/usecases/auth/sign_in_usecase.dart';
import 'package:flutterbase/application/usecases/auth/sign_out_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/add_bookmark_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/get_bookmark_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/list_bookmarks_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/open_bookmark_usecase.dart';
import 'package:flutterbase/application/usecases/bookmark/remove_bookmark_usecase.dart';
import 'package:flutterbase/application/usecases/debug/get_debug_settings_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_debug_mode_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_log_level_usecase.dart';
import 'package:flutterbase/application/usecases/language/get_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/language/set_language_preference_usecase.dart';
import 'package:flutterbase/application/usecases/notices/dismiss_notice_usecase.dart';
import 'package:flutterbase/application/usecases/notices/list_notices_usecase.dart';
import 'package:flutterbase/application/usecases/notices/mark_all_notices_read_usecase.dart';
import 'package:flutterbase/application/usecases/notices/mark_notice_read_usecase.dart';
import 'package:flutterbase/application/usecases/notices/open_notice_link_usecase.dart';
import 'package:flutterbase/application/usecases/theme/get_theme_preference_usecase.dart';
import 'package:flutterbase/application/usecases/theme/set_theme_preference_usecase.dart';
import 'package:flutterbase/domain/value_objects/sign_in_settings.dart';
import 'package:flutterbase/presentation/providers/app_info_providers.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';
import 'package:flutterbase/presentation/providers/app_update_providers.dart';
import 'package:flutterbase/presentation/providers/auth_providers.dart';
import 'package:flutterbase/presentation/providers/bookmark_providers.dart';
import 'package:flutterbase/presentation/providers/debug_providers.dart';
import 'package:flutterbase/presentation/providers/language_providers.dart';
import 'package:flutterbase/presentation/providers/notice_providers.dart';
import 'package:flutterbase/presentation/providers/theme_providers.dart';

/// Bridges the service locator to Riverpod.
///
/// The providers in `presentation/providers/` declare *what* a screen needs
/// and throw if read un-overridden; this list is the only place that says
/// *which* instance satisfies each one. Keeping the bridge in the composition
/// root is what lets Presentation stay unaware of `get_it`, and what makes a
/// widget test able to swap any single use case for a fake by overriding the
/// same provider.
///
/// Only use-case seams appear here. The providers that hold screen state —
/// `themeModeProvider` and friends — build themselves from these, so the
/// composition root never has to name a piece of UI state.
List<Override> buildProviderOverrides() {
  return <Override>[
    appLoggerProvider.overrideWithValue(sl<AppLogger>()),
    // Theme.
    getThemePreferenceUseCaseProvider.overrideWithValue(
      sl<GetThemePreferenceUseCase>(),
    ),
    setThemePreferenceUseCaseProvider.overrideWithValue(
      sl<SetThemePreferenceUseCase>(),
    ),
    // Language.
    getLanguagePreferenceUseCaseProvider.overrideWithValue(
      sl<GetLanguagePreferenceUseCase>(),
    ),
    setLanguagePreferenceUseCaseProvider.overrideWithValue(
      sl<SetLanguagePreferenceUseCase>(),
    ),
    // Debug settings.
    getDebugSettingsUseCaseProvider.overrideWithValue(
      sl<GetDebugSettingsUseCase>(),
    ),
    setDebugModeUseCaseProvider.overrideWithValue(sl<SetDebugModeUseCase>()),
    setLogLevelUseCaseProvider.overrideWithValue(sl<SetLogLevelUseCase>()),
    // App info.
    getAppInfoUseCaseProvider.overrideWithValue(sl<GetAppInfoUseCase>()),
    // Bookmarks.
    listBookmarksUseCaseProvider.overrideWithValue(sl<ListBookmarksUseCase>()),
    getBookmarkUseCaseProvider.overrideWithValue(sl<GetBookmarkUseCase>()),
    addBookmarkUseCaseProvider.overrideWithValue(sl<AddBookmarkUseCase>()),
    removeBookmarkUseCaseProvider.overrideWithValue(
      sl<RemoveBookmarkUseCase>(),
    ),
    openBookmarkUseCaseProvider.overrideWithValue(sl<OpenBookmarkUseCase>()),
    // Optional sign-in. The use cases exist only when it is on; the screens
    // never read them otherwise (the menu entry is hidden).
    signInSettingsProvider.overrideWithValue(sl<SignInSettings>()),
    if (sl<SignInSettings>().isEnabled) ...[
      getCurrentAccountUseCaseProvider.overrideWithValue(
        sl<GetCurrentAccountUseCase>(),
      ),
      signInUseCaseProvider.overrideWithValue(sl<SignInUseCase>()),
      signOutUseCaseProvider.overrideWithValue(sl<SignOutUseCase>()),
      // Update notice and notices from the paired web app (docs/adr/0009-*).
      checkForUpdateUseCaseProvider.overrideWithValue(
        sl<CheckForUpdateUseCase>(),
      ),
      dismissUpdateUseCaseProvider.overrideWithValue(
        sl<DismissUpdateUseCase>(),
      ),
      openUpdateDownloadUseCaseProvider.overrideWithValue(
        sl<OpenUpdateDownloadUseCase>(),
      ),
      listNoticesUseCaseProvider.overrideWithValue(sl<ListNoticesUseCase>()),
      markNoticeReadUseCaseProvider.overrideWithValue(
        sl<MarkNoticeReadUseCase>(),
      ),
      markAllNoticesReadUseCaseProvider.overrideWithValue(
        sl<MarkAllNoticesReadUseCase>(),
      ),
      dismissNoticeUseCaseProvider.overrideWithValue(
        sl<DismissNoticeUseCase>(),
      ),
      openNoticeLinkUseCaseProvider.overrideWithValue(
        sl<OpenNoticeLinkUseCase>(),
      ),
    ],
  ];
}
