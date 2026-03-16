import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dependency Injection wiring for the application.
///
/// All infrastructure bindings are registered here.
/// UseCases receive their dependencies via constructor injection.
///
/// Example:
/// ```dart
/// final wordRepositoryProvider = Provider<WordRepository>((ref) {
///   final db = ref.watch(appDatabaseProvider);
///   return SqliteWordRepository(db);
/// });
/// ```
///
/// This file grows as new features are added. Keep each binding
/// scoped narrowly to its layer.

// Placeholder — add providers here as features are implemented.
final appModuleInitializedProvider = Provider<bool>((ref) => true);
