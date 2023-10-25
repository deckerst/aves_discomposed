import 'dart:async';

import 'package:discomposed/discomposed.dart';
import 'package:flutter_nsd/flutter_nsd.dart';

// TODO IMPORTANT: Android emulator doesn't support Network Service Discovery so you'll have to use a real device.
class NSDServiceDiscoverer implements ServiceDiscoverer {
  final _flutterNsd = FlutterNsd();

  // FIXME This is some mutable thing for now.
  var nsdServiceInfos = <NsdServiceInfo>[];

  @override
  Future<Set<Service>> findAllServices() async {
    print('[Discomposed:NSD] Init search...');

    unawaited(initServiceStream());

    print('[Discomposed:NSD] Starting search...');
    await startDiscovery();

    print('[Discomposed:NSD] Started search. ${DateTime.now().millisecondsSinceEpoch}');
    return Future.delayed(const Duration(seconds: 5), () async {
      await stopDiscovery();

      var services = nsdServiceInfos
          .map((nsdService) => Service(nsdService.name!, 'NSD', '${nsdService.hostname}:${nsdService.port}',
              nsdService.txt!.map((key, value) => MapEntry(key, value.toString())), 'NSD'))
          .toSet();

      print('[Discomposed:NSD] Finished search, found: [$services]. ${DateTime.now().millisecondsSinceEpoch}');
      return services;
    });
  }

  Future<void> initServiceStream() async {
    final stream = _flutterNsd.stream;

    stream.handleError(
        (Object error, StackTrace trace) => {print('[Discomposed:NSD] Error intercepted, $error, stack: $trace')},
        test: (e) => true);

    await for (final nsdServiceInfo in stream) {
      print('[Discomposed:NSD] Discovered service name: ${nsdServiceInfo.name}');
      print('[Discomposed:NSD] Discovered service hostname/IP: ${nsdServiceInfo.hostname}');
      print('[Discomposed:NSD] Discovered service port: ${nsdServiceInfo.port}');
      nsdServiceInfos.add(nsdServiceInfo);
    }
  }

  Future<void> startDiscovery() async {
    try {
      return await _flutterNsd.discoverServices('_services._tcp.');
    } catch (e) {
      print('[Discomposed:NSD] Error starting service discoverer: ${e.toString()}');
    }
  }

  Future<void> stopDiscovery() async {
    try {
      return await _flutterNsd.stopDiscovery();
    } catch (e) {
      print('[Discomposed:NSD] Error stopping service discoverer: ${e.toString()}');
    }
  }
}
