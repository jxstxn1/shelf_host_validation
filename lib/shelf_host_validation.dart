/// Support for doing something awesome.
///
/// More dartdocs go here.
library shelf_host_validation;

import 'package:shelf/shelf.dart';

/// Enum to determine the used ValidationMode
enum ValidationMode { either, both }

/// Middleware to validate the Host header or Referer Header of a request
///
/// [hosts] is a list of allowed hosts, can be a RegExp or a String
///
/// [referer] is list of allowed referer, can be a RegExp or a String
///
/// [mode] is the [ValidationMode], either or both
///
/// [errorResponse] is the [Response] which is returned if the validation fails
Middleware validateHost({
  List<Pattern>? hosts,
  List<Pattern>? referers,
  ValidationMode mode = ValidationMode.both,
  Response? errorResponse,
}) {
  return (innerHandler) {
    return (request) {
      if (hosts == null && referers == null) {
        throw 'either hosts or referers must included';
      }

      if (hosts != null && hosts.isEmpty) {
        throw 'hosts cannot be empty';
      }
      if (referers != null && referers.isEmpty) {
        throw 'referers cannot be empty';
      }

      bool allowed = true;
      if (mode == ValidationMode.both) {
        if (hosts != null && referers != null) {
          allowed = isAllowed(
                request.headers['Host'] ?? '',
                hosts,
              ) &&
              isAllowed(
                request.headers['Referer'] ?? '',
                referers,
              );
        } else if (hosts != null && request.headers['Host'] != null) {
          allowed = isAllowed(request.headers['Host']!, hosts);
        } else if (referers != null && request.headers['Referer'] != null) {
          allowed = isAllowed(request.headers['Referer']!, referers);
        } else {
          allowed = false;
        }
      } else {
        allowed = isAllowed(request.headers['Host'] ?? '', hosts ?? []) ||
            isAllowed(request.headers['Referer'] ?? '', referers ?? []);
      }

      if (allowed) {
        return innerHandler(request);
      } else {
        return errorResponse ?? Response(403, body: 'Forbidden');
      }
    };
  };
}

bool isAllowed(String headerValue, List<Pattern> allowedValues) {
  bool allowed = false;
  for (final allowedValue in allowedValues) {
    if (allowed) break;
    if (allowedValue is String) {
      allowed = allowedValue == headerValue;
    } else if (allowedValue is RegExp) {
      allowed = allowedValue.hasMatch(headerValue);
    }
  }
  return allowed;
}
