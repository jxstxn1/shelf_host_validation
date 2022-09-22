import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf_host_validation/shelf_host_validation.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Should throw: ', () {
    test(" 'hosts and referer cannot both be null' if wheter a host or referer list is set", () async {
      final handler = const Pipeline().addMiddleware(validateHost()).addHandler(syncHandler);
      expectLater(
        makeRequest(handler, uri: clientUri, method: 'GET'),
        throwsA('either hosts or referers must included'),
      );
    });

    test(" 'hosts cannot be empty' if hosts is empty", () {
      final handler = const Pipeline().addMiddleware(validateHost(hosts: [])).addHandler(syncHandler);
      expectLater(
        makeRequest(handler, uri: clientUri, method: 'GET'),
        throwsA('hosts cannot be empty'),
      );
    });

    test(" 'referers cannot be empty' if referer is empty", () {
      final handler = const Pipeline().addMiddleware(validateHost(referers: [])).addHandler(syncHandler);
      expectLater(
        makeRequest(handler, uri: clientUri, method: 'GET'),
        throwsA('referers cannot be empty'),
      );
    });
  });

  group('Dev Host : ', () {
    final handler = validateHost(hosts: ['127.0.0.1:4322', 'localhost:4322'])(syncHandler);

    testHeader(
      handler: handler,
      headers: {'Host': '127.0.0.1:4322'},
    );
    testHeader(
      handler: handler,
      headers: {'Host': 'localhost:4322'},
    );
    testHeader(
      handler: handler,
      headers: {'Host': 'DNSRebind-attack.com'},
      shouldBeAllowed: false,
    );
  });

  group('Host : ', () {
    final handler = validateHost(
      hosts: [
        'mydomain.com',
        'myseconddomain.com',
        'subdomain.mydomain.com',
        'subdomain.mythirddomain.com',
        RegExp(r'/^.*.regexdomain\.com$/'),
      ],
    )(syncHandler);

    testHeader(
      handler: handler,
      headers: {'Host': 'mydomain.com'},
    );
    testHeader(
      handler: handler,
      headers: {'Host': 'subdomain.mydomain.com'},
    );
    testHeader(
      handler: handler,
      headers: {'Host': 'myseconddomain.com'},
    );
    testHeader(
      handler: handler,
      headers: {'Host': 'mythirddomain.com'},
      shouldBeAllowed: false,
    );
    testHeader(
      handler: handler,
      headers: {'Host': 'subdomain.mythirddomain.com'},
    );
  });

  group('Referer : ', () {
    final handler = validateHost(
      referers: [
        'https://camefromhere.com',
        'https://camefromhere.com/specific-page',
        RegExp('https://camefromhere.com/allowed/.*'),
      ],
    )(syncHandler);

    testHeader(
      handler: handler,
      headers: {'Referer': 'https://camefromhere.com'},
    );

    testHeader(
      handler: handler,
      headers: {'Referer': 'http://camefromhere.com'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Referer': 'https://camefromhere.com/specific-page'},
    );

    testHeader(
      handler: handler,
      headers: {'Referer': 'https://camefromhere.com/different-page'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Referer': 'https://camefromhere.com/allowed/page'},
    );

    testHeader(
      handler: handler,
      headers: {'Referer': 'https://camefromhere.com/allowed'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Referer': 'http://shouldnt-be-allowed-to-come-from-here.com'},
      shouldBeAllowed: false,
    );
  });

  group('Host & Referer : ', () {
    final handler = validateHost(
      hosts: ['trusted-host.com'],
      referers: ['http://trusted-host.com/login.php'],
    )(syncHandler);

    testHeader(
      handler: handler,
      headers: {
        'Host': 'trusted-host.com',
      },
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'http://trusted-host.com/login.php',
      },
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {
        'Host': 'trusted-host.com',
        'Referer': 'http://trusted-host.com/login.php',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Host': 'trusted-host.com',
        'Referer': 'http://trusted-host.com/index.php',
      },
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {
        'Host': 'untrusted-host.com',
        'Referer': 'http://trusted-host.com/login.php',
      },
      shouldBeAllowed: false,
    );
  });

  group('Host or Refererer : ', () {
    final handler = validateHost(
      hosts: ['trusted-host.com'],
      referers: ['http://trusted-host.com/login.php'],
      mode: ValidationMode.either,
    )(syncHandler);

    testHeader(
      handler: handler,
      headers: {
        'Host': 'trusted-host.com',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'http://trusted-host.com/login.php',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Host': 'trusted-host.com',
        'Referer': 'http://trusted-host.com/login.php',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Host': 'trusted-host.com',
        'Referer': 'http://trusted-host.com/index.php',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Host': 'untrusted-host.com',
        'Referer': 'http://trusted-host.com/login.php',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'http://trusted-host.com/index.php',
      },
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {
        'Host': 'untrusted-host.com',
      },
      shouldBeAllowed: false,
    );
  });

  group('LAN Host Regex Test : ', () {
    // regex to match '192.168.1.1-255' (actually matches '192.168.1.001-255' too, but w/e...)
    final lanHostRegex = RegExp(r'^192\.168\.1\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$');
    final handler = validateHost(
      hosts: [lanHostRegex],
    )(syncHandler);

    testHeader(
      handler: handler,
      headers: {'Host': '192.168.1.83'},
    );

    testHeader(
      handler: handler,
      headers: {'Host': '192.168.1.1'},
    );

    testHeader(
      handler: handler,
      headers: {'Host': '192.168.1.255'},
    );

    testHeader(
      handler: handler,
      headers: {'Host': '192.168.2.1'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Host': '10.0.0.1'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Host': '192.168.1.256'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Host': '192.168.2556'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Host': 'mydomain.com'},
      shouldBeAllowed: false,
    );
  });

  group('LAN Referer Regex : ', () {
    final lanHostRegex = RegExp(r'^http:\/\/192\.168\.1\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])(\/.*){0,1}$');
    final handler = validateHost(
      hosts: [lanHostRegex],
    )(syncHandler);

    testHeader(
      handler: handler,
      headers: {'Host': 'http://192.168.1.83'},
    );

    testHeader(
      handler: handler,
      headers: {'Host': 'http://192.168.1.83/'},
    );

    testHeader(
      handler: handler,
      headers: {'Host': 'http://192.168.1.1/router_login.html'},
    );

    testHeader(
      handler: handler,
      headers: {'Host': 'http://192.168.1.1/login'},
    );

    testHeader(
      handler: handler,
      headers: {'Host': 'http://192.168.2.1'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Host': 'http://10.0.0.1'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Host': 'http://10.0.0.1/login'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Host': 'http://192.168.1.2556'},
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {'Host': 'http://mydomain.com'},
      shouldBeAllowed: false,
    );
  });

  group('https referer : ', () {
    final handler = validateHost(
      referers: [RegExp(r'^https:\/\/')],
    )(syncHandler);

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'https://google.com',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'https://localhost',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'https://github.com/login',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'http://google.com',
      },
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'http://localhost',
      },
      shouldBeAllowed: false,
    );

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'http://github.com/login',
      },
      shouldBeAllowed: false,
    );
  });

  group('Custom Fail : ', () {
    FutureOr<Response> Function(Request) handler = const Pipeline()
        .addMiddleware(
          validateHost(
            referers: [RegExp(r'^https:\/\/')],
            errorResponse: Response(
              // using 401 instead of 403 for testing purposes only
              401,
              body: 'Forbidden: Referer must be an HTTPS site.',
            ),
          ),
        )
        .addHandler(syncHandler);

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'https://google.com',
      },
    );

    testHeader(
      handler: handler,
      headers: {
        'Referer': 'https://github.com/login',
      },
    );

    test("{'Referer': 'http://localhost'} should get a custom errorResponse", () async {
      final response = await makeRequest(
        handler,
        uri: clientUri,
        method: 'GET',
        headers: {'Referer': 'http://localhost'},
      );
      expect(
        response.statusCode,
        401,
      );
      expectLater(
        response.readAsString(),
        completion('Forbidden: Referer must be an HTTPS site.'),
      );
    });

    test("{'Referer': 'http://google.com'} should get a custom errorResponse", () async {
      // Need to re-create the handler because you can read a response body only once
      handler = validateHost(
        referers: [RegExp(r'^https:\/\/')],
        errorResponse: Response(
          // using 401 instead of 403 for testing purposes only
          401,
          body: 'Forbidden: Referer must be an HTTPS site.',
        ),
      )(syncHandler);

      final response = await makeRequest(
        handler,
        uri: clientUri,
        method: 'GET',
        headers: {'Referer': 'http://google.com'},
      );

      expect(response.statusCode, 401);
      expectLater(
        response.readAsString(),
        completion('Forbidden: Referer must be an HTTPS site.'),
      );
    });
  });

  group('Custom Fail Teapot : ', () {
    final handler = const Pipeline()
        .addMiddleware(
          validateHost(
            hosts: ['office-teapot'],
            errorResponse: Response(418, body: "I'm the office teapot. Refer to me only as such."),
          ),
        )
        .addHandler(syncHandler);

    testHeader(
      handler: handler,
      headers: {
        'Host': 'office-teapot',
      },
    );

    test("{'Host': 'office-coffeepot'} should get a custom errorResponse", () async {
      final response = await makeRequest(
        handler,
        uri: clientUri,
        method: 'GET',
        headers: {'Host': 'office-coffeepot'},
      );

      expect(response.statusCode, 418);
      expectLater(
        response.readAsString(),
        completion("I'm the office teapot. Refer to me only as such."),
      );
    });
  });
}
