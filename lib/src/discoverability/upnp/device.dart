import 'package:discomposed/src/discoverability/upnp/service.dart';
import 'package:discomposed/src/discoverability/upnp/utils.dart';
import 'package:xml/xml.dart';

// Adapted from https://github.com/SpinlockLabs/upnp.dart
class Device {
  late XmlElement deviceElement;

  String? deviceType;
  String? urlBase;
  String? friendlyName;
  String? manufacturer;
  String? modelName;
  String? udn;
  String? uuid;
  String? url;
  String? presentationUrl;
  String? modelType;
  String? modelDescription;
  String? modelNumber;
  String? manufacturerUrl;

  List<Icon> icons = [];
  List<ServiceDescription?> services = [];

  List<String?> get serviceNames => services.map((x) => x?.id).toList();

  void loadFromXml(String? u, XmlElement e) {
    url = u;
    deviceElement = e;

    var uri = Uri.parse(url!);

    urlBase = XmlUtils.getTextSafe(deviceElement, 'URLBase');

    urlBase ??= uri.toString();

    if (deviceElement.findElements('device').isEmpty) {
      throw Exception('ERROR: Invalid Device XML!\n\n$deviceElement');
    }

    var deviceNode = XmlUtils.getElementByName(deviceElement, 'device');

    deviceType = XmlUtils.getTextSafe(deviceNode, 'deviceType');
    friendlyName = XmlUtils.getTextSafe(deviceNode, 'friendlyName');
    modelName = XmlUtils.getTextSafe(deviceNode, 'modelName');
    manufacturer = XmlUtils.getTextSafe(deviceNode, 'manufacturer');
    udn = XmlUtils.getTextSafe(deviceNode, 'UDN');
    presentationUrl = XmlUtils.getTextSafe(deviceNode, 'presentationURL');
    modelType = XmlUtils.getTextSafe(deviceNode, 'modelType');
    modelDescription = XmlUtils.getTextSafe(deviceNode, 'modelDescription');
    manufacturerUrl = XmlUtils.getTextSafe(deviceNode, 'manufacturerURL');

    if (udn != null) {
      uuid = udn!.substring('uuid:'.length);
    }

    if (deviceNode.findElements('iconList').isNotEmpty) {
      var iconList = deviceNode.findElements('iconList').first;
      for (var child in iconList.children) {
        if (child is XmlElement) {
          var icon = Icon();
          icon.mimetype = XmlUtils.getTextSafe(child, 'mimetype');
          var width = XmlUtils.getTextSafe(child, 'width');
          var height = XmlUtils.getTextSafe(child, 'height');
          var depth = XmlUtils.getTextSafe(child, 'depth');
          var url = XmlUtils.getTextSafe(child, 'url');
          if (width != null) {
            icon.width = int.parse(width);
          }

          if (height != null) {
            icon.height = int.parse(height);
          }

          if (depth != null) {
            icon.depth = int.parse(depth);
          }

          icon.url = url;

          icons.add(icon);
        }
      }
    }

    var baseUri = Uri.parse(urlBase!);

    void processDeviceNode(XmlElement e) {
      if (e.findElements('serviceList').isNotEmpty) {
        var list = e.findElements('serviceList').first;
        for (var svc in list.children) {
          if (svc is XmlElement) {
            services.add(ServiceDescription.fromXml(baseUri, svc));
          }
        }
      }

      if (e.findElements('deviceList').isNotEmpty) {
        var list = e.findElements('deviceList').first;
        for (var dvc in list.children) {
          if (dvc is XmlElement) {
            processDeviceNode(dvc);
          }
        }
      }
    }

    processDeviceNode(deviceNode);
  }
}

class Icon {
  String? mimetype;
  int? width;
  int? height;
  int? depth;
  String? url;
}
