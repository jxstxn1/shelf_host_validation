# Example

## Add the Middleware your Shelf API

by simply adding:

 ```dart
 .addMiddleware(validateHost(host: ['localhost:3000'])),
 ```

you can define a custom error Response by setting the `errorResponse` parameter:

```dart
.addMiddleware(
    enforceSSL(
        errorResponse: Response(
            403,
            body: 'Only use HTTPS when you try to send data to this API',
        ),
    ),
),
```

you can also add use the Middleware in DartFrog by doing the following:

```dart
Handler maxContentLengthValidator(Handler handler) {
    return handler.use(fromShelfMiddleware(enforceSSl()));
}
```

### Full example

```dart
import 'package:shelf_host_validation/shelf_host_validation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final handler = const Pipeline()
      .addMiddleware(
        .addMiddleware(
      validateHost(
        hosts: ['YOUR_HOST_URL'],
        referers: [RegExp(r'^https:\/\/'),],
            errorResponse: Response(
                403,
                body: 'Only use HTTPS when you try to send data to this API',
            ),
        ),
    ),
    .addMiddleware(logRequests())
    .addHandler(_echoRequest);

  final server = await shelf_io.serve(handler, 'localhost', 8080);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}

Response _echoRequest(Request request) => Response.ok('Request for "${request.url}"');
```
