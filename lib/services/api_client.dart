import 'dart:async';
import 'dart:convert';

import 'api_transport.dart';

/// Error returned by the Pinspire API or by the network layer.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode = 0, this.errors = const {}});

  final String message;
  final int statusCode;
  final Map<String, List<String>> errors;

  bool get isUnauthorized => statusCode == 401;

  /// First validation message, useful for forms and snackbars.
  String? get firstError {
    for (final messages in errors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return null;
  }

  @override
  String toString() => firstError ?? message;
}

/// Envelope returned by the API: `{success, message, data, meta}`.
class ApiResult {
  const ApiResult(this.data, this.meta);

  final dynamic data;
  final Map<String, dynamic> meta;

  List<Map<String, dynamic>> get items {
    final value = data;
    if (value is List) {
      return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    return const [];
  }

  Map<String, dynamic> get object {
    final value = data;
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.transport,
    this.onUnauthorized,
  });

  final String baseUrl;
  final ApiTransport transport;
  void Function()? onUnauthorized;

  String? token;

  Map<String, String> get _baseHeaders => {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<ApiResult> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<ApiResult> post(
    String path, {
    Object? body,
    Map<String, String> fields = const {},
    List<ApiFile> files = const [],
    Map<String, String>? query,
  }) => _send(
    'POST',
    path,
    body: body,
    fields: fields,
    files: files,
    query: query,
  );

  Future<ApiResult> patch(
    String path, {
    Object? body,
    Map<String, String> fields = const {},
    List<ApiFile> files = const [],
  }) => _send('PATCH', path, body: body, fields: fields, files: files);

  Future<ApiResult> put(
    String path, {
    Object? body,
    Map<String, String> fields = const {},
    List<ApiFile> files = const [],
  }) => _send('PUT', path, body: body, fields: fields, files: files);

  Future<ApiResult> delete(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  /// Sends a multipart update using method spoofing because PHP only parses
  /// multipart bodies for POST requests.
  Future<ApiResult> multipartUpdate(
    String path, {
    Map<String, String> fields = const {},
    List<ApiFile> files = const [],
  }) =>
      _send('POST', path, fields: {...fields, '_method': 'PUT'}, files: files);

  Future<ApiResult> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String> fields = const {},
    List<ApiFile> files = const [],
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    var uri = Uri.parse('$baseUrl$normalizedPath');
    if (query != null) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }

    final headers = Map<String, String>.from(_baseHeaders);
    String? encodedBody;
    if (files.isEmpty && fields.isEmpty && body != null) {
      headers['Content-Type'] = 'application/json';
      encodedBody = jsonEncode(body);
    }

    ApiResponse response;
    try {
      response = await transport
          .send(
            ApiRequest(
              method: method,
              url: uri.toString(),
              headers: headers,
              body: encodedBody,
              fields: fields,
              files: files,
            ),
          )
          .timeout(const Duration(seconds: 35));
    } on ApiTransportException catch (error) {
      throw ApiException(error.message);
    } on TimeoutException {
      throw ApiException(
        'Permintaan ke server melebihi batas waktu. Coba lagi.',
      );
    } catch (_) {
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan API Pinspire berjalan di $baseUrl.',
      );
    }

    Map<String, dynamic> decoded = const {};
    if (response.body.trim().isNotEmpty) {
      try {
        final value = jsonDecode(response.body);
        if (value is Map) decoded = Map<String, dynamic>.from(value);
      } catch (_) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw ApiException('Respons server tidak dapat dibaca.');
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final meta = decoded['meta'];
      return ApiResult(
        decoded['data'],
        meta is Map ? Map<String, dynamic>.from(meta) : const {},
      );
    }

    if (response.statusCode == 401) onUnauthorized?.call();

    final errors = <String, List<String>>{};
    final rawErrors = decoded['errors'];
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        if (value is List) {
          errors['$key'] = value.map((item) => '$item').toList();
        } else if (value != null) {
          errors['$key'] = ['$value'];
        }
      });
    }

    final message = decoded['message'] is String
        ? decoded['message'] as String
        : 'Permintaan gagal (${response.statusCode}).';
    throw ApiException(
      message,
      statusCode: response.statusCode,
      errors: errors,
    );
  }
}
