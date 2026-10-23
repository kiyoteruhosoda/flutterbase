import 'package:flutterbase/domain/entities/service_outage.dart';

/// Base class for all typed application errors.
sealed class AppError implements Exception {
  const AppError(this.message);
  final String message;
}

/// An error originating from a domain rule violation.
final class DomainError extends AppError {
  const DomainError(super.message);
}

/// An error from the infrastructure layer (I/O, network, DB).
final class InfrastructureError extends AppError {
  const InfrastructureError(super.message, {this.cause});
  final Object? cause;
}

/// The paired web app answered `503` with the edge's JSON: it is closed for
/// maintenance or stopped. Every screen gives way to the maintenance screen
/// until it answers again (docs/adr/0011-in-app-maintenance-screen.md).
final class ServiceUnavailableError extends AppError {
  const ServiceUnavailableError(super.message, this.outage);
  final ServiceOutage outage;
}

/// An unexpected / unclassified runtime error.
final class UnexpectedError extends AppError {
  const UnexpectedError(super.message, {this.cause, this.stackTrace});
  final Object? cause;
  final StackTrace? stackTrace;
}

/// There is no usable sign-in: never signed in, signed out, or the sign-in
/// ran out. Only what needs a sign-in stops; the rest of the app is unaffected.
final class SignInRequiredError extends AppError {
  const SignInRequiredError(super.message);
}

/// The person closed the sign-in page without finishing. Not a failure to
/// report, only a reason to stop.
final class SignInCancelledError extends AppError {
  const SignInCancelledError(super.message);
}
