import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'api_models.dart';

ApiTransport createTransport() => IoApiTransport();

/// Native implementation of the API transport built on `HttpClient`.
class IoApiTransport implements ApiTransport {
  const IoApiTransport();

  static const _timeout = Duration(seconds: 30);

  @override
  Future<ApiResponse> send(ApiRequest request) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final uri = Uri.parse(request.url);
      final httpRequest = await client.openUrl(request.method, uri);
      request.headers.forEach(httpRequest.headers.set);

      if (request.isMultipart) {
        final boundary = '----pinspire${DateTime.now().microsecondsSinceEpoch}';
        httpRequest.headers.set(
          HttpHeaders.contentTypeHeader,
          'multipart/form-data; boundary=$boundary',
        );
        httpRequest.add(_multipartBody(request, boundary));
      } else if (request.body != null) {
        httpRequest.add(utf8.encode(request.body!));
      }

      final response = await httpRequest.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join();
      return ApiResponse(response.statusCode, text);
    } finally {
      client.close(force: true);
    }
  }

  Uint8List _multipartBody(ApiRequest request, String boundary) {
    final builder = BytesBuilder(copy: false);

    for (final field in request.fields.entries) {
      builder.add(
        utf8.encode(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="${_escape(field.key)}"\r\n'
          '\r\n'
          '${field.value}\r\n',
        ),
      );
    }

    for (final file in request.files) {
      builder.add(
        utf8.encode(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="${_escape(file.field)}"; '
          'filename="${_escape(file.filename)}"\r\n'
          'Content-Type: ${file.mimeType}\r\n'
          '\r\n',
        ),
      );
      builder.add(file.bytes);
      builder.add(utf8.encode('\r\n'));
    }

    builder.add(utf8.encode('--$boundary--\r\n'));
    return builder.takeBytes();
  }

  String _escape(String value) => value.replaceAll('"', '\\"');
}
