/// Updates of this app handed out through the store it was installed from
/// (Google Play's in-app updates, docs/adr/0012-*).
///
/// An outbound port: the Application layer states what it needs, and
/// `infrastructure/store/` supplies the platform implementation.
///
/// The store decides everything here — whether a newer build is out for this
/// device, and the download itself. A copy installed from anywhere else (the
/// APK on share.nolumia.com, a local build) has no store to ask, and every
/// call answers "nothing".
///
/// **Never throws.** An update offer is a courtesy; a store that cannot be
/// asked is the same as one with nothing to say.
abstract interface class StoreUpdateGateway {
  /// Where the store stands on an update for this app.
  Future<StoreUpdateStatus> check();

  /// Asks the store to download the update in the background, after the
  /// store's own prompt, and completes when the download has finished. True
  /// when it is ready to [install]; false when the person declined or the
  /// store could not fetch it.
  Future<bool> download();

  /// Installs a downloaded update. The store restarts the app to do it.
  Future<void> install();
}

/// What the store says about an update for this app.
enum StoreUpdateStatus {
  /// No newer build, or no store to ask.
  none,

  /// A newer build is out and may be downloaded while the app keeps running.
  available,

  /// A newer build has already been downloaded and waits to be installed.
  downloaded,
}
