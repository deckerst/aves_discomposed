@Skip('Requires a physical IOS / Android device')
import 'dart:convert';

import 'package:discomposed/src/discoverability/nsd/client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('it will return all NSD scanned services', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // given
    var serviceDiscoverer = NSDServiceDiscoverer();

    // when
    var services = await serviceDiscoverer.findAllServices();

    // then
    var servicesJson = JsonEncoder.withIndent('  ').convert(services.toList());
    print('---\nThe following services were discovered:\n\n$servicesJson');

    expect(services.length, greaterThanOrEqualTo(2));
  });
}
