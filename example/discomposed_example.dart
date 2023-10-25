import 'dart:convert';

import 'package:discomposed/discomposed.dart';

void main() async {
  var serviceDiscoverer = CompositeServiceDiscoverer();
  var services = await serviceDiscoverer.findAllServices();

  var servicesJson = JsonEncoder.withIndent('  ').convert(services.toList());
  print('---\nThe following services were discovered:\n\n$servicesJson');
}
