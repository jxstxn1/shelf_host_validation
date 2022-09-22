# Shelf Host Validation

Middleware that protects Shelf and DartFrog servers from [DNS Rebinding](https://en.wikipedia.org/wiki/DNS_rebinding) attacks by validating Host and Referer [sic] headers from incoming requests. If a request doesn't contain a whitelisted Host/Referer header, `shelf_host_validation` will respond with a 403 Forbidden HTTP error. Inspired by <https://github.com/brannondorsey/host-validation>

## Installing

```sh
dart pub add shelf_enforces_ssl
```

## Usage

Parameters:

- [hosts] is a list of allowed hosts, can be a RegExp or a String
- [referer] is list of allowed referer, can be a RegExp or a String
- [mode] is the [ValidationMode], either or both
- [errorResponse] is the [Response] which is returned if the validation fails

### As shelf middleware

```dart
import 'package:shelf_host_validation/shelf_host_validation.dart';

var handler = const Pipeline()
    .addMiddleware(
      validateHost(
        hosts: ['trusted-host.com'],
        referers: [
          'http://trusted-host.com/login.php',
          RegExp(r'^https:\/\/'),
        ],
      ),
    )
    .addMiddleware(logRequests())
    .addHandler(_echoRequest);
```

### As dart_frog middleware

```dart
import 'package:shelf_host_validation/shelf_host_validation.dart';

Handler enforceSSL(Handler handler) {
  return handler.use(
    fromShelfMiddleware(
      validateHost(
        hosts: ['trusted-host.com'],
        referers: [
          'http://trusted-host.com/login.php',
          RegExp(r'^https:\/\/'),
        ],
      ),
    ),
  );
}
```
