FORKED from published discomposed v0.0.1-alpha03 (private repository: https://github.com/davehancock/discomposed)

YASDL - Yet another service discovery library.

Composes together some common service discovery techniques to ease local network device connectivity.

## Usage

A simple usage example:

```dart
import 'dart:convert';

import 'package:discomposed/discomposed.dart';

void main() async {
  var serviceDiscoverer = ServiceDiscoverer();
  var services = await serviceDiscoverer.findAllServices();

  var servicesJson = JsonEncoder.withIndent('  ').convert(services.toList());
  print('---\nThe following services were discovered:\n\n${servicesJson}');
}
```

## Platform Compatibility

TODO Put a table here of the different discovery mechanisms

TODO Migrate the docs about SSDP, MDS, NSD, UPNP, N-UPNP etc etc here too.

TODO Use https://www.tablesgenerator.com/markdown_tables for ease

|         | SSDP               | MDS                | NSD                | UPNP               | N-UPNP             |
|---------|--------------------|--------------------|--------------------|--------------------|--------------------|
| Android | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| iOS     | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| Web     | :x:                | :x:                | :x:                | :white_check_mark: | :white_check_mark: |
| Desktop | :white_check_mark: | :white_check_mark: | :x:                | :white_check_mark: | :white_check_mark: |

## TODO Fixes

Philips Hue

- Philips Hue (hap and hue) when scanned via MDNS is a little flaky. I.e on first scan shows, on later doesn't
- It could be due to id / origin IP used on first scan? I.e maybe it thinks its already responded?
- It could be due to time spent scanning, maybe it will only poll in certain time frames?


