import 'package:flutterbase/application/ports/app_logger.dart';
import 'package:flutterbase/domain/entities/app_release.dart';
import 'package:flutterbase/domain/repositories/dismissed_update_repository.dart';

/// Closes the update banner for [AppRelease.build] only: the next newer build
/// shows it again.
final class DismissUpdateUseCase {
  const DismissUpdateUseCase(this._dismissed, this._logger);

  final DismissedUpdateRepository _dismissed;
  final AppLogger _logger;

  Future<void> execute(AppRelease release) async {
    await _dismissed.save(release.build);
    _logger.info('[Update] banner closed for $release');
  }
}
