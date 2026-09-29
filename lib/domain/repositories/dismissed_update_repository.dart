/// Remembers which update the person closed the banner for.
///
/// One build number, not a list: closing the banner for build N hides it for
/// N and anything older, and the next newer build shows it again.
/// Implementations live in `infrastructure/repositories/`.
abstract interface class DismissedUpdateRepository {
  /// The build number whose banner was last closed, or null.
  int? get();

  /// Remembers that the banner for [build] was closed.
  Future<void> save(int build);
}
