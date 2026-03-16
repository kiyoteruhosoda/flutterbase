/// アプリ共通エラー基底クラス
sealed class AppError implements Exception {
  const AppError(this.message);
  final String message;
}

/// ドメイン層エラー
final class DomainError extends AppError {
  const DomainError(super.message);
}

/// インフラ層エラー
final class InfrastructureError extends AppError {
  const InfrastructureError(super.message, {this.cause});
  final Object? cause;
}

/// 予期しないエラー
final class UnexpectedError extends AppError {
  const UnexpectedError(super.message, {this.cause});
  final Object? cause;
}
