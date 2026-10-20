import 'dart:typed_data';

/// A file that will be sent as part of a multipart request.
class ApiFile {
  const ApiFile({
    required this.field,
    required this.filename,
    required this.bytes,
    this.mimeType = 'application/octet-stream',
  });

  final String field;
  final String filename;
  final Uint8List bytes;
  final String mimeType;
}

/// A transport agnostic HTTP request.
class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
    this.fields = const {},
    this.files = const [],
  });

  final String method;
  final String url;
  final Map<String, String> headers;

  /// JSON encoded body used for regular requests.
  final String? body;

  /// Multipart text fields.
  final Map<String, String> fields;

  /// Multipart files.
  final List<ApiFile> files;

  bool get isMultipart => fields.isNotEmpty || files.isNotEmpty;
}

class ApiResponse {
  const ApiResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class ApiTransportException implements Exception {
  const ApiTransportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Small abstraction so the app can use `dart:io` on native and
/// `XMLHttpRequest` on the web without importing platform libraries directly.
abstract class ApiTransport {
  Future<ApiResponse> send(ApiRequest request);
}
