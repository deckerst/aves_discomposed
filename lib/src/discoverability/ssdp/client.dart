import 'package:discomposed/discomposed.dart';
import 'package:discomposed/src/discoverability/upnp/device.dart';
import 'package:discomposed/src/discoverability/upnp/discovery.dart';

class SSDPServiceDiscoverer implements ServiceDiscoverer {
  @override
  Future<Set<Service>> findAllServices() async {
    var client = DeviceDiscoverer();
    await client.start(ipv6: false);

    print('[Discomposed:SSDP] Starting search...');
    var services = <Service>{};
    client.quickDiscoverClients().listen((client) async {
      try {
        var dev = await client.getDevice();
        if (dev == null) {
          print('[Discomposed:SSDP] failed to get device for location=${client.location}');
        } else {
          var metadata = _parseMetadata(dev);
          services.add(Service(dev.friendlyName!, dev.deviceType, dev.url, metadata, 'SSDP'));
        }
      } catch (e) {
        print('[Discomposed:SSDP] ERROR: $e - ${client.location} ');
      }
    });

    return Future.delayed(const Duration(seconds: 5), () {
      client.stop();
      print('[Discomposed:SSDP] Finished search, found: [$services]');
      return services;
    });
  }

  Map<String, String?> _parseMetadata(Device dev) {
    var metadata = <String, String?>{};
    metadata['urlBase'] = dev.urlBase!;
    metadata['friendlyName'] = dev.friendlyName;
    metadata['manufacturer'] = dev.manufacturer;
    metadata['manufacturerUrl'] = dev.manufacturerUrl;
    metadata['modelName'] = dev.modelName;
    metadata['udn'] = dev.udn!;
    metadata['presentationUrl'] = dev.presentationUrl;
    metadata['icon'] = (dev.icons.isNotEmpty) ? dev.icons.first.url : '';
    return metadata;
  }
}
