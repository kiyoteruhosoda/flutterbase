import 'dart:convert';

import 'package:flutterbase/application/ports/auth_session.dart';
import 'package:flutterbase/domain/entities/account.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/infrastructure/auth/oidc_client.dart';
import 'package:flutterbase/infrastructure/auth/secret_store.dart';

/// [AuthSession] for assay (docs/adr/0007-optional-assay-sign-in.md).
///
/// Only the refresh token and the display name are persisted, both in
/// secure storage; the access token (valid for 300 s) lives in memory.
///
/// Refreshes are serialised: assay rotates the refresh token on every use
/// and treats a reused one as theft, revoking the whole family — so two
/// concurrent refreshes with the same token would sign the person out.
final class OidcAuthSession implements AuthSession {
  OidcAuthSession(this._client, this._secrets, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const String refreshTokenKey = 'oidc.refresh_token';
  static const String accountKey = 'oidc.account';

  /// Refresh this long before expiry, so a token never dies in flight.
  static const Duration _margin = Duration(seconds: 30);

  final OidcClient _client;
  final SecretStore _secrets;
  final DateTime Function() _now;

  String? _accessToken;
  DateTime? _expiresAt;
  Future<String>? _refreshing;

  @override
  Future<Account?> currentAccount() async {
    final stored = await _secrets.read(accountKey);
    if (stored == null) return null;
    if (await _secrets.read(refreshTokenKey) == null) return null;
    final json = jsonDecode(stored) as Map<String, Object?>;
    return Account(
      displayName: json['name']! as String,
      email: json['email'] as String?,
    );
  }

  @override
  Future<Account> signIn() async {
    final tokens = await _client.authorize();
    final refreshToken = tokens.refreshToken;
    if (refreshToken == null) {
      throw const SignInRequiredError(
        'The sign-in returned no refresh token (offline_access refused?).',
      );
    }
    final account = accountFromIdToken(tokens.idToken);
    await _secrets.write(refreshTokenKey, refreshToken);
    await _secrets.write(
      accountKey,
      jsonEncode(<String, Object?>{
        'name': account.displayName,
        'email': account.email,
      }),
    );
    _remember(tokens);
    return account;
  }

  @override
  Future<void> signOut() async {
    _accessToken = null;
    _expiresAt = null;
    await _secrets.delete(refreshTokenKey);
    await _secrets.delete(accountKey);
  }

  @override
  Future<String> accessToken({bool forceRefresh = false}) {
    final token = _accessToken;
    final expiresAt = _expiresAt;
    if (!forceRefresh &&
        token != null &&
        expiresAt != null &&
        _now().toUtc().isBefore(expiresAt.subtract(_margin))) {
      return Future.value(token);
    }
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String> _refresh() async {
    final refreshToken = await _secrets.read(refreshTokenKey);
    if (refreshToken == null) {
      throw const SignInRequiredError('Not signed in.');
    }
    final OidcTokens tokens;
    try {
      tokens = await _client.refresh(refreshToken);
    } on SignInRequiredError {
      await signOut();
      rethrow;
    }
    final rotated = tokens.refreshToken;
    if (rotated != null) await _secrets.write(refreshTokenKey, rotated);
    _remember(tokens);
    return tokens.accessToken;
  }

  void _remember(OidcTokens tokens) {
    _accessToken = tokens.accessToken;
    _expiresAt = tokens.expiresAt;
  }
}

/// Reads who signed in from an ID token's claims.
///
/// The token came straight from the token endpoint over TLS, so its claims
/// are only displayed, never trusted for access — the signature is the
/// server's business when it checks the access token.
Account accountFromIdToken(String? idToken) {
  Map<String, Object?> claims = const {};
  final parts = idToken?.split('.') ?? const <String>[];
  if (parts.length == 3) {
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      claims = jsonDecode(payload) as Map<String, Object?>;
    } on FormatException {
      // Unreadable claims only cost us the display name.
    }
  }
  String? claim(String name) {
    final value = claims[name];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  final email = claim('email');
  return Account(
    displayName:
        claim('name') ??
        claim('preferred_username') ??
        email ??
        claim('sub') ??
        '?',
    email: email,
  );
}
