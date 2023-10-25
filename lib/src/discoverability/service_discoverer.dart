import 'package:discomposed/src/discoverability/mdns/client.dart';
import 'package:discomposed/src/discoverability/nsd/client.dart';
import 'package:discomposed/src/discoverability/service.dart';
import 'package:discomposed/src/discoverability/ssdp/client.dart';

// TODO Add on a generic query method too?
abstract class ServiceDiscoverer {
  Future<Set<Service>> findAllServices();
}

class CompositeServiceDiscoverer implements ServiceDiscoverer {
  final List<ServiceDiscoverer> _serviceDiscoverers;

  static final List<ServiceDiscoverer> _defaultServiceDiscoverers = [
    MDnsServiceDiscoverer(),
    SSDPServiceDiscoverer(),
    NSDServiceDiscoverer()
  ];

  CompositeServiceDiscoverer() : _serviceDiscoverers = _defaultServiceDiscoverers;

  CompositeServiceDiscoverer.WithAdditional(List<ServiceDiscoverer> additionalServiceDiscoverers)
      : _serviceDiscoverers = [..._defaultServiceDiscoverers, ...additionalServiceDiscoverers];

  @override
  Future<Set<Service>> findAllServices() async {
    var futureServiceList = _serviceDiscoverers.map((e) => e.findAllServices()).toList();

    var partiallyCompleteServices = <Set<Service>>[];
    try {
      var allServices = await Future.wait(futureServiceList, cleanUp: (Set<Service> successfulResult) {
        partiallyCompleteServices.add(successfulResult);
      });
      return allServices.expand((element) => element).toSet();
    } catch (e, s) {
      print('An error occurred on discovery: ${e.toString()} \n$s');
      return partiallyCompleteServices.expand((element) => element).toSet();
    }
  }
}
