import 'dart:async';
import 'dart:convert';

import 'package:flutterbase/application/ports/auth_session.dart';
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
/// is no usable sign-in, [InfrastructureError] for everything the network or
/// the server did.
final class WebApiClient {
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
    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      throw InfrastructureError('$method $path answered $status.');
    }
    return response;
  }

  Future<http.Response> _once(
    String method,
    Uri url,
    String token,
    Map<String, Object?>? body,
  ) async {
    final request = http.Request(method, url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';
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
