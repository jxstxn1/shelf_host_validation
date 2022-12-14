import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final Uri clientUri = Uri.parse('http://127.0.0.1:4322/');

/// Copied from the Shelf package.
/// https://github.com/dart-lang/shelf/blob/master/pkgs/shelf/test/test_util.dart
/// A simple, synchronous handler for [Request].
///
/// By default, replies with a status code 200, empty headers, and
/// `Hello from ${request.url.path}`.
Response syncHandler(
  Request request, {
  int? statusCode,
  Map<String, String>? headers,
}) {
  return Response(
    statusCode ?? 200,
    headers: headers,
    body: 'Hello from ${request.requestedUri.path}',
  );
}

Future<Response> makeRequest(
  Handler handler, {
  required Uri uri,
  required String method,
  Map<String, Object>? headers,
  Object? body,
}) {
  return Future.sync(
    () {
      return handler(
        Request(
          method,
          uri,
          headers: headers,
          body: body,
        ),
      );
    },
  );
}

void testHeader({
  required FutureOr<Response> Function(Request) handler,
  required Map<String, Object> headers,
  bool shouldBeAllowed = true,
}) {
  return test(
      '$headers ${shouldBeAllowed ? 'should be allowed' : 'should not be allowed'}',
      () async {
    final response = await makeRequest(
      handler,
      uri: clientUri,
      method: 'GET',
      headers: headers,
    );
    expect(
      response.statusCode,
      shouldBeAllowed ? 200 : 403,
    );
  });
}
