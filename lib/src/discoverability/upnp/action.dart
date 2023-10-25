import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:discomposed/src/discoverability/upnp/service.dart';
import 'package:xml/xml.dart';

import 'utils.dart';

// Adapted from https://github.com/SpinlockLabs/upnp.dart
class Action {
  late Service service;
  late String name;
  List<ActionArgument> arguments = [];

  Action.fromXml(XmlElement e) {
    name = XmlUtils.getTextSafe(e, 'name')!;

    void addArgDef(XmlElement argdef, [bool stripPrefix = false]) {
      var name = XmlUtils.getTextSafe(argdef, 'name');

      if (name == null) {
        return;
      }

      var direction = XmlUtils.getTextSafe(argdef, 'direction');
      var relatedStateVariable = XmlUtils.getTextSafe(argdef, 'relatedStateVariable');
      var isRetVal = direction == 'out';

      if (this.name.startsWith('Get')) {
        var of = this.name.substring(3);
        if (of == name) {
          isRetVal = true;
        }
      }

      if (name.startsWith('Get') && stripPrefix) {
        name = name.substring(3);
      }

      arguments.add(ActionArgument(this, name, direction, relatedStateVariable, isRetVal));
    }

    var argumentLists = e.findElements('argumentList');
    if (argumentLists.isNotEmpty) {
      var argList = argumentLists.first;
      if (argList.children.any((x) => x is XmlElement && x.name.local == 'name')) {
        // Bad UPnP Implementation fix for WeMo
        addArgDef(argList, true);
      } else {
        for (var argdef in argList.children.whereType<XmlElement>()) {
          addArgDef(argdef);
        }
      }
    }
  }
}

class StateVariable {
  late Service service;
  late String name;
  late String dataType;
  dynamic defaultValue;
  bool doesSendEvents = false;

  StateVariable();

  StateVariable.fromXml(XmlElement e) {
    name = XmlUtils.getTextSafe(e, 'name')!;
    dataType = XmlUtils.getTextSafe(e, 'dataType')!;
    defaultValue = XmlUtils.asValueType(XmlUtils.getTextSafe(e, 'defaultValue'), dataType);
    doesSendEvents = e.getAttribute('sendEvents') == 'yes';
  }

  String getGenericId() {
    return sha1.convert(utf8.encode('${service.device!.uuid}::${service.id}::$name')).toString();
  }
}

class ActionArgument {
  final Action action;
  final String name;
  final String? direction;
  final String? relatedStateVariable;
  final bool isRetVal;

  ActionArgument(this.action, this.name, this.direction, this.relatedStateVariable, this.isRetVal);

  StateVariable? getStateVariable() {
    if (relatedStateVariable != null) {
      return null;
    }

    var vars = action.service.stateVariables!.where((x) => x.name == relatedStateVariable);

    if (vars.isNotEmpty) {
      return vars.first;
    }

    return null;
  }
}
