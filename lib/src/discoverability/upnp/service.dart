import 'package:discomposed/src/discoverability/upnp/action.dart';
import 'package:discomposed/src/discoverability/upnp/device.dart';
import 'package:discomposed/src/discoverability/upnp/utils.dart';
import 'package:xml/xml.dart';

// Adapted from https://github.com/SpinlockLabs/upnp.dart
class ServiceDescription {
  late String? type;
  late String? id;
  late String? controlUrl;
  late String? eventSubUrl;
  late String? scpdUrl;

  ServiceDescription.fromXml(Uri uriBase, XmlElement service) {
    type = XmlUtils.getTextSafe(service, 'serviceType')!.trim();
    id = XmlUtils.getTextSafe(service, 'serviceId')!.trim();
    controlUrl = uriBase.resolve(XmlUtils.getTextSafe(service, 'controlURL')!.trim()).toString();
    eventSubUrl = uriBase.resolve(XmlUtils.getTextSafe(service, 'eventSubURL')!.trim()).toString();

    var m = XmlUtils.getTextSafe(service, 'SCPDURL');

    if (m != null) {
      scpdUrl = uriBase.resolve(m).toString();
    }
  }
}

class Service {
  final Device? device;
  final String? type;
  final String? id;
  final List<Action>? actions;
  final List<StateVariable>? stateVariables;

  String? controlUrl;
  String? eventSubUrl;
  String? scpdUrl;

  Service(this.device, this.type, this.id, this.controlUrl, this.eventSubUrl, this.scpdUrl, this.actions,
      this.stateVariables);

  List<String>? get actionNames => actions?.map((x) => x.name).toList();
}
