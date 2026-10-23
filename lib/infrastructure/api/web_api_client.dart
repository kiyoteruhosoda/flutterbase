import 'dart:async';
import 'dart:convert';

import 'package:flutterbase/application/ports/auth_session.dart';
import 'package:flutterbase/application/ports/service_status.dart';
import 'package:flutterbase/domain/entities/service_outage.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:http/http.dart' as http;

/// Calls the paired web app's API as the signed-in person.
///
/// Every request carries `Authorization: Bearer <assay access token>` from
/// [AuthSession.accessToken] — the same token the web app's `/api/app/me`
/// accepts (the web app admits it by `client_id`, `APP_CLIENT_IDS`). A 401 is
/// answered once by forcing a refresh and retrying: the token is short-lived
/// (300 s) and the server's clock is the one that counts.
///
/// Failures reach the caller as [AppError]s: [SignInRequiredError] when there
/// is no usable sign-in, [ServiceUnavailableError] when the edge answered
/// `503` with its maintenance / stopped JSON (also reported on [outages];
/// docs/adr/0011-in-app-maintenance-screen.md), [InfrastructureError] for
/// everything else the network or the server did.
final class WebApiClient implements ServiceStatus {
  WebApiClient(
    this._session,
    this.baseUrl, {
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _http = httpClient ?? http.Client();

  final AuthSession _session;
  final http.Client _http;

  /// Origin of the web app, e.g. `https://recipebox.nolumia.com`.
  final Uri baseUrl;
  final Duration timeout;

  /// What [check] asks. Any path would do while the edge is closed (it answers
  /// every request on the host). Once open, any answer means "back": this
  /// one answers 401 without a token, or 404 where a web app dropped it.
  static const String checkPath = '/api/app/me';

  final StreamController<ServiceOutage> _outages =
      StreamController<ServiceOutage>.broadcast();

  @override
  Stream<ServiceOutage> get outages => _outages.stream;

  /// Asks [checkPath] without a token: the edge answers before any sign-in
  /// is looked at, and a sign-in that ran out must not read as an outage.
  @override
  Future<ServiceOutage?> check() async {
    final response = await _once('GET', baseUrl.resolve(checkPath), null, null);
    return serviceOutageFrom(response);
  }

  /// Stops [outages] and the HTTP client.
  Future<void> close() async {
    _http.close();
    await _outages.close();
  }

  /// `GET` [path] and decode its JSON body.
  Future<Object?> getJson(String path) async {
    final response = await _send('GET', path);
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw InfrastructureError('GET $path answered with no JSON.', cause: e);
    }
  }

  /// `POST` [path] with no body, for the endpoints that answer 204.
  Future<void> post(String path) async {
    await _send('POST', path);
  }

  /// `POST` [path] with [body] as JSON, for the endpoints that answer 204.
  Future<void> postJson(String path, Map<String, Object?> body) async {
    await _send('POST', path, body: body);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final url = baseUrl.resolve(path);
    var response = await _once(method, url, await _session.accessToken(), body);
    if (response.statusCode == 401) {
      response = await _once(
        method,
        url,
        await _session.accessToken(forceRefresh: true),
        body,
      );
    }
    final outage = serviceOutageFrom(response);
    if (outage != null) {
      _outages.add(outage);
      throw ServiceUnavailableError(
        '$method $path answered 503 (${outage.reason.name}).',
        outage,
      );
    }
    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      throw InfrastructureError('$method $path answered $status.');
    }
    return response;
  }

  Future<http.Response> _once(
    String method,
    Uri url,
    String? token,
    Map<String, Object?>? body,
  ) async {
    final request = http.Request(method, url)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    try {
      final streamed = await _http.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException catch (e) {
      throw InfrastructureError('$method ${url.path} timed out.', cause: e);
    } on http.ClientException catch (e) {
      throw InfrastructureError('$method ${url.path} failed.', cause: e);
    }
  }
}

/// The outage the edge's `503` JSON describes, or null for any other answer.
///
/// Only a `503` whose body is `{"error": "service_unavailable", "reason":
/// "maintenance" | "stopped", ...}` counts. A `503` with HTML or with another
/// shape — the web app's own, a proxy's — stays an ordinary failure.
/// Text fields that are missing, empty, or not strings are null, and so is an
/// `until` that is not an ISO 8601 instant.
ServiceOutage? serviceOutageFrom(http.Response response) {
  if (response.statusCode != 503) return null;
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(response.bodyBytes));
  } on FormatException {
    return null;
  }
  if (json is! Map<String, Object?> || json['error'] != 'service_unavailable') {
    return null;
  }
  final reason = switch (json['reason']) {
    'maintenance' => ServiceOutageReason.maintenance,
    'stopped' => ServiceOutageReason.stopped,
    _ => null,
  };
  if (reason == null) return null;
  final fields = json;

  String? text(String key) {
    final value = fields[key];
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  final until = text('until');
  return ServiceOutage(
    reason: reason,
    title: text('title'),
    body: text('body'),
    message: text('message'),
    until: until == null ? null : DateTime.tryParse(until)?.toUtc(),
  );
}
