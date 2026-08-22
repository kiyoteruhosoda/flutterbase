import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/application/usecases/debug/get_debug_settings_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_debug_mode_usecase.dart';
import 'package:flutterbase/application/usecases/debug/set_log_level_usecase.dart';
import 'package:flutterbase/domain/value_objects/log_level.dart';
import 'package:flutterbase/presentation/providers/app_providers.dart';

// ─── Use-case seams ────────────────────────────────────────────────────────

final Provider<GetDebugSettingsUseCase> getDebugSettingsUseCaseProvider =
    Provider<GetDebugSettingsUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('getDebugSettingsUseCaseProvider'),
      );
    });

final Provider<SetDebugModeUseCase> setDebugModeUseCaseProvider =
    Provider<SetDebugModeUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('setDebugModeUseCaseProvider'),
      );
    });

final Provider<SetLogLevelUseCase> setLogLevelUseCaseProvider =
    Provider<SetLogLevelUseCase>((ref) {
      throw UnimplementedError(
        missingOverrideMessage('setLogLevelUseCaseProvider'),
      );
    });

// ─── App-wide state ────────────────────────────────────────────────────────
//
// Debug mode and log level are two independent preferences, so they get one
// provider each: the drawer only cares whether developer entries are visible
// and does not rebuild when the log level changes.

/// Whether developer-only entries (Logs, Debug Info) are visible.
final NotifierProvider<DebugModeNotifier, bool> debugModeProvider =
    NotifierProvider<DebugModeNotifier, bool>(DebugModeNotifier.new);

/// The minimum severity the app logger records.
final NotifierProvider<LogLevelNotifier, LogLevel> logLevelProvider =
    NotifierProvider<LogLevelNotifier, LogLevel>(LogLevelNotifier.new);

/// Loads the stored debug-mode flag and writes changes back to it.
class DebugModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final enabled = ref
        .read(getDebugSettingsUseCaseProvider)
        .executeDebugMode();
    ref.read(appLoggerProvider).debug('[Debug] init — debugEnabled: $enabled');
    return enabled;
  }

  /// Persists [value], then adopts it.
  ///
  /// Unlike theme and language there is no early-out: the switch is the
  /// source of truth and a redundant write is harmless.
  Future<void> setEnabled(bool value) async {
    ref.read(appLoggerProvider).info('[Debug] setDebugEnabled: $value');
    await ref.read(setDebugModeUseCaseProvider).execute(value);
    state = value;
  }
}

/// Loads the stored log level and writes changes back to it.
class LogLevelNotifier extends Notifier<LogLevel> {
  @override
  LogLevel build() {
    final level = ref.read(getDebugSettingsUseCaseProvider).executeLogLevel();
    ref.read(appLoggerProvider).debug('[Debug] init — logLevel: ${level.name}');
    return level;
  }

  /// Persists [level] — which also applies it to the logger — then adopts it.
  Future<void> setLevel(LogLevel level) async {
    ref.read(appLoggerProvider).info('[Debug] setLogLevel: ${level.name}');
    await ref.read(setLogLevelUseCaseProvider).execute(level);
    state = level;
  }
}
