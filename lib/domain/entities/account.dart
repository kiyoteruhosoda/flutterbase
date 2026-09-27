/// The person signed in to the optional sign-in, as far as the app needs to
/// show them: who is signed in, not what they may do.
final class Account {
  const Account({required this.displayName, this.email});

  /// Name to show. Falls back to the email or the subject when the identity
  /// provider sent no name.
  final String displayName;

  final String? email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.displayName == displayName &&
          other.email == email);

  @override
  int get hashCode => Object.hash(displayName, email);

  @override
  String toString() => 'Account($displayName)';
}
