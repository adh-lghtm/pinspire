import 'dart:async';
import 'dart:js_interop';

import 'api_models.dart';

ApiTransport createTransport() => WebApiTransport();

@JS('XMLHttpRequest')
extension type _XmlHttpRequest._(JSObject _) implements JSObject {
  external factory _XmlHttpRequest();

  external void open(String method, String url);
  external void setRequestHeader(String name, String value);
  external void send([JSAny? body]);

  external int get status;
  external String get responseText;
  external set responseType(String value);
  external set timeout(int milliseconds);
  external set onload(JSFunction callback);
  external set onerror(JSFunction callback);
  external set ontimeout(JSFunction callback);
}

@JS('FormData')
extension type _FormData._(JSObject _) implements JSObject {
  external factory _FormData();

  external void append(String name, JSAny? value, [String? filename]);
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny?> parts, [JSObject options]);
}

/// Browser implementation of the API transport using `XMLHttpRequest`.
///
/// `fetch` is not used because `FormData` uploads with progress-free XHR keep
/// the implementation compatible with Dart's JS interop without extra packages.
class WebApiTransport implements ApiTransport {
  const WebApiTransport();

  @override
  Future<ApiResponse> send(ApiRequest request) {
    final completer = Completer<ApiResponse>();
    final xhr = _XmlHttpRequest();
    xhr.open(request.method, request.url);

    for (final header in request.headers.entries) {
      xhr.setRequestHeader(header.key, header.value);
    }

    xhr.responseType = 'text';
    xhr.timeout = 30000;
    xhr.onload = (() {
      if (!completer.isCompleted) {
        completer.complete(ApiResponse(xhr.status, xhr.responseText));
      }
    }).toJS;
    xhr.onerror = (() {
      if (!completer.isCompleted) {
        completer.completeError(
          const ApiTransportException(
            'Tidak dapat terhubung ke server. Periksa koneksi dan pastikan API berjalan.',
          ),
        );
      }
    }).toJS;
    xhr.ontimeout = (() {
      if (!completer.isCompleted) {
        completer.completeError(
          const ApiTransportException(
            'Permintaan ke server melebihi batas waktu.',
          ),
        );
      }
    }).toJS;

    try {
      if (request.isMultipart) {
        final form = _FormData();
        for (final field in request.fields.entries) {
          form.append(field.key, field.value.toJS);
        }
        for (final file in request.files) {
          final blob = _Blob(
            <JSAny>[file.bytes.toJS].toJS,
            <String, String>{'type': file.mimeType}.jsify() as JSObject,
          );
          form.append(file.field, blob, file.filename);
        }
        xhr.send(form);
      } else if (request.body != null) {
        xhr.send(request.body!.toJS);
      } else {
        xhr.send();
      }
    } catch (error) {
      if (!completer.isCompleted) {
        completer.completeError(ApiTransportException('$error'));
      }
    }

    return completer.future;
  }
}
