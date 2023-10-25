@Skip('Requires compatible env with real services and UDP etc')
import 'dart:convert';

import 'package:discomposed/src/discoverability/service_discoverer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('it will return all scanned services', () async {
    // given
    var serviceDiscoverer = CompositeServiceDiscoverer();

    // when
    var services = await serviceDiscoverer.findAllServices();

    // then
    var servicesJson = JsonEncoder.withIndent('  ').convert(services.toList());
    print('---\nThe following services were discovered:\n$servicesJson');

    expect(services.length, greaterThanOrEqualTo(2));
  });
}
