import 'package:flutter/foundation.dart';
import 'package:flutterbase/application/dto/app_info_dto.dart';
import 'package:flutterbase/application/usecases/app_info/get_app_info_usecase.dart';
import 'package:flutterbase/shared/errors/app_error.dart';
import 'package:flutterbase/shared/logging/app_logger.dart';

/// UI state for the Debug page.
enum DebugState { loading, loaded, error }

/// ViewModel for [DebugPage].
///
/// Loads app info via [GetAppInfoUseCase] and exposes log management
/// operations through [AppLogger]. Contains no business logic.
class DebugViewModel extends ChangeNotifier {
  DebugViewModel(this._getAppInfo, this._logger);

  final GetAppInfoUseCase _getAppInfo;
  final AppLogger _logger;

  DebugState _state = DebugState.loading;
  AppInfoDto? _appInfo;
  AppError? _error;

  DebugState get state => _state;
  AppInfoDto? get appInfo => _appInfo;
  AppError? get appError => _error;

  Future<void> loadAppInfo() async {
    _state = DebugState.loading;
    _error = null;
    notifyListeners();

    try {
      _appInfo = await _getAppInfo.execute();
      _state = DebugState.loaded;
    } catch (e, st) {
      _error = UnexpectedError('Failed to load debug info', cause: e, stackTrace: st);
      _state = DebugState.error;
    } finally {
      notifyListeners();
    }
  }

  void clearLogs() {
    _logger.clearBuffer();
    notifyListeners();
  }
}
