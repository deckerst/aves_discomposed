import 'dart:io';

import 'package:discomposed/discomposed.dart';
import 'package:multicast_dns/multicast_dns.dart';

class MDnsServiceDiscoverer implements ServiceDiscoverer {
  static final Duration defaultTimeout = const Duration(seconds: 5);
  static final String mdsAllServiceQuery = '_services._dns-sd._udp.local';

  late RawDatagramSocketFactory _socketFactory;

  MDnsServiceDiscoverer() {
    _socketFactory = (dynamic host, int port, {bool? reuseAddress, bool? reusePort, int? ttl}) {
      print('[Discomposed:MDNS] Attempting socket bind: '
          'host: [$host], port: [$port], reuseAddress: [$reuseAddress], reusePort: [$reusePort], ttl: [$ttl]');
      // TODO Reuse of port can cause issues on different platforms
      return RawDatagramSocket.bind(host, port, reuseAddress: true, reusePort: true);
    };
  }

  @override
  Future<Set<Service>> findAllServices() async {
    return findServices(mdsAllServiceQuery);
  }

  /// Accepts a [serviceQuery] term and returns resolvable services via mDNS.
  ///
  /// The [serviceQuery] could be a given service type identifier that contains a
  /// service type directly, or a matching generic query e.g:
  /// - a service type + proto + domain (_hue._tcp.local)
  /// - a wildcard service term (_services._dns-sd._udp.local)
  ///
  ///  TODO Probably need some graceful handling throughout here...
  Future<Set<Service>> findServices(String serviceQuery) async {
    // TODO There's some (seemingly) broken behaviour with the internal cache when using wildcard queries here...
    // So creating a new local instance each time instead...
    var _mDnsClient = MDnsClient(rawDatagramSocketFactory: _socketFactory);
    print('[Discomposed:MDNS] Starting search...');

    try {
      await _mDnsClient.start();
    } catch (e) {
      print('[Discomposed:MDNS] failed to start client: $e');
      return <Service>{};
    }

    var serviceDefinitionFutures = <Future<Set<Service>>>[];

    print('[Discomposed:MDNS] Starting Root search');
    await for (PtrResourceRecord ptr in _mDnsClient
        .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(serviceQuery), timeout: defaultTimeout)) {
      print('[Discomposed:MDNS] Root Search Term [$serviceQuery] Domain [${ptr.domainName}]');
      serviceDefinitionFutures.add(_searchForAllServicesWhere(_mDnsClient, serviceQuery, ptr.domainName));
    }
    print('[Discomposed:MDNS] Finished Root search');

    var serviceDefinitionGroups = await Future.wait(serviceDefinitionFutures,
        cleanUp: (dynamic x) => print('[Discomposed:MDNS] **** There was an error: [${x.toString()}]'));
    var serviceDefinitions = serviceDefinitionGroups.expand((e) => e).toSet();

    _mDnsClient.stop();

    print('[Discomposed:MDNS] Finished search, found: [$serviceDefinitions]');
    return serviceDefinitions;
  }

  Future<Set<Service>> _searchForAllServicesWhere(
      MDnsClient _mDnsClient, String serviceQuery, String domainName) async {
    var serviceListFutures = <Future<Set<Service>>>[];
    var srvRecords =
        _mDnsClient.lookup<SrvResourceRecord>(ResourceRecordQuery.service(domainName), timeout: defaultTimeout);
    if (await srvRecords.isEmpty) {
      print(
          '[Discomposed:MDNS] Search Term [$serviceQuery] Domain [$domainName] has no direct service results, may be wildcard search');
      serviceListFutures.add(_findServiceDefinitionsFor(_mDnsClient, domainName));
    } else {
      print('[Discomposed:MDNS] Search Term [$serviceQuery] with Domain [$domainName] has specific service results');
      serviceListFutures.add(_findServiceDefinitionsFor(_mDnsClient, serviceQuery));
    }

    var listOfSetOfServices = await Future.wait(serviceListFutures);
    var services = listOfSetOfServices.expand((e) => e).toSet();

    return services;
  }

  Future<Set<Service>> _findServiceDefinitionsFor(MDnsClient _mDnsClient, String serviceTypeIdentifier) async {
    var services = <Service>{};
    await for (PtrResourceRecord ptr in _mDnsClient
        .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(serviceTypeIdentifier), timeout: defaultTimeout)) {
      print('[Discomposed:MDNS] PTR Record: [${ptr.toString()}]');

      await for (SrvResourceRecord srv in _mDnsClient
          .lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName), timeout: defaultTimeout)) {
        print('[Discomposed:MDNS] Srv Record: [${srv.toString()}]');

        await for (IPAddressResourceRecord a in _mDnsClient
            .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target), timeout: defaultTimeout)) {
          print('[Discomposed:MDNS] IPAddress Record: [${a.toString()}]');

          await for (TxtResourceRecord txt in _mDnsClient
              .lookup<TxtResourceRecord>(ResourceRecordQuery.text(ptr.domainName), timeout: defaultTimeout)) {
            print('[Discomposed:MDNS] Txt Record: [${txt.toString()}]');

            services.add(Service(
                _parseSimpleServiceName(txt.name),
                _parseSimpleServiceType(serviceTypeIdentifier),
                _parseServiceLocation(a.address.address, srv.port),
                _parseRawTxtRecord(txt.text),
                'MDNS'));
          }
        }
      }
    }
    return services;
  }

  static String _parseServiceLocation(String ipAddress, [int port = 8080]) {
    return '$ipAddress:$port';
  }

  // TODO Probably should have some graceful handling in here to protect against bad input
  static Map<String, String> _parseRawTxtRecord(String txtRecordValue) {
    var items = txtRecordValue.split('\n').where((e) => e.isNotEmpty).toList();
    var entries = {for (var e in items) e.split('=')[0]: e.split('=')[1]};
    return entries;
  }

  static String _parseSimpleServiceType(String serviceTypeIdentifier) {
    return _extractFirstDelimited(serviceTypeIdentifier);
  }

  static String _parseSimpleServiceName(String serviceInstanceName) {
    return _extractFirstDelimited(serviceInstanceName);
  }

  static String _extractFirstDelimited(String str) {
    var first = str.split('.')[0];
    return first.replaceAll('_', '');
  }
}
