@Skip('Requires compatible env with real services and UDP etc')
import 'dart:convert';

import 'package:discomposed/src/discoverability/mdns/client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('it will return an mdns specific service', () async {
    // given
    var serviceDiscoverer = MDnsServiceDiscoverer();

    // when
    var services = await serviceDiscoverer.findServices('_hue._tcp.local');

    // then
    expect(services.length, 1);

    var hueService = services.first;
    expect(hueService.name, 'Philips Hue - 011828');
    expect(hueService.type, 'hue');
    expect(hueService.address, '192.168.1.163:443');
    expect(hueService.metadata, {'bridgeid': 'ecb5fafffe011828', 'modelid': 'BSB002'});
  });

  test('it will return all mdns scanned services', () async {
    // given
    var serviceDiscoverer = MDnsServiceDiscoverer();

    // when
    var services = await serviceDiscoverer.findAllServices();

    // then
    var servicesJson = JsonEncoder.withIndent('  ').convert(services.toList());
    print('---\nThe following services were discovered:\n\n$servicesJson');

    expect(services.length, greaterThanOrEqualTo(2));
  });
}
