/// Base class for all domain-level errors.
///
/// Domain errors are expected failures (validation errors, not-found, etc.)
/// as opposed to unexpected system failures (which bubble up as exceptions).
sealed class AppError {
  const AppError({required this.code, required this.message});

  /// Machine-readable error code.
  final String code;

  /// Developer-facing message (NOT user-facing UI strings).
  final String message;

  @override
  String toString() => 'AppError($code): $message';
}

/// Resource was not found.
class NotFoundError extends AppError {
  const NotFoundError({required String resource})
      : super(
          code: 'NOT_FOUND',
          message: 'Resource not found: $resource',
        );
}

/// Input validation failed.
class ValidationError extends AppError {
  const ValidationError({required String field, required String detail})
      : super(
          code: 'VALIDATION_ERROR',
          message: 'Validation failed for $field: $detail',
        );

  factory ValidationError.required(String field) =>
      ValidationError(field: field, detail: 'is required');

  factory ValidationError.tooLong(String field, int max) =>
      ValidationError(field: field, detail: 'exceeds max length of $max');

  factory ValidationError.tooShort(String field, int min) =>
      ValidationError(field: field, detail: 'must be at least $min characters');
}

/// Operation is not permitted given current state.
class InvalidStateError extends AppError {
  const InvalidStateError({required String detail})
      : super(
          code: 'INVALID_STATE',
          message: detail,
        );
}

/// Conflict with existing data.
class ConflictError extends AppError {
  const ConflictError({required String detail})
      : super(
          code: 'CONFLICT',
          message: detail,
        );
}
