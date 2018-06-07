library dart_database.field;

import 'dart:mirrors';
import './main.dart';
import './utils.dart';

class Field {
  final String name;
  final Type type;
  final InstanceMirror field;

  Field(this.name, this.type, this.field);
  
  static dynamic parseByteArray(List<int> byteList, [int offset = 0]) {
    List<int> bytes = byteList.sublist(offset);
    Type fieldType;
    int typeByte = bytes[0];

    if (bytes.length < 3) {
      throw new Exception('Malformed buffer. Field should be more than 2 bytes long');
    }
    switch(typeByte) {
      case 0x01:
        fieldType = String;
        break;
      case 0x02:
        fieldType = int;
        break;
      case 0x03:
        fieldType = bool;
        break;
      default:
        throw new Exception('Cannot recognize datatype');
    }
    int nameLength = bytes[1];
    int valueOffset = nameLength + 2;
    String fieldName = new String.fromCharCodes(bytes.getRange(2, valueOffset));
    int valueStart = valueOffset + 4;
    int valueLength = byteListToInt(bytes.getRange(valueOffset, valueStart));
    dynamic fieldValue;
    List<int> dataBuffer = bytes.getRange(valueStart, valueStart + valueLength);

    switch(typeByte) {
      case 0x01:
        fieldValue = new String.fromCharCodes(dataBuffer);
        break;
      case 0x02:
        fieldValue = byteListToInt(dataBuffer);
        break;
      case 0x03:
        fieldValue = bytes[valueStart] == 1;
        break;
      default:
        throw new Exception('Cannot recognize datatype');
    }
    
    return [
      fieldName,
      fieldType,
      fieldValue,
      offset + valueStart + valueLength,
    ];
  }

  List<int> serialize() => new List<int>()
    ..addAll(_serializeDefinition())
    ..addAll(_serializeValue())
    ..toList(growable: false);

  List<int> _serializeDefinition() {
    List<int> nameBytes = name.codeUnits;
    int typeByte = _getTypeByte();
    List<int> result = new List();
    
    if (nameBytes.length > 255) {
      throw new Exception('field name cannot be larger than 255 symbols');
    }

    result.add(typeByte);
    result.add(nameBytes.length);
    result.addAll(nameBytes);

    return result.toList(growable: false);
  }

  List<int> _serializeValue() {
    List<int> valueBytes = _valueToByteArray();
    List<int> valueLength = intToByteListBE(valueBytes.length, 4);

    return new List<int>()
      ..addAll(valueLength)
      ..addAll(valueBytes)
      ..toList(growable: false);
  }

  _getTypeByte() {
    switch (type) {
      case String:
        return 0x01;
      case int:
        return 0x02;
      case bool:
        return 0x03;
      // case double:
      //   return 0x04;
      default:
        throw new Exception('Unknown type $type');
    }
  }

  _valueToByteArray() {
    dynamic value = field.reflectee;

    switch (type) {
      case String:
        return (value as String).codeUnits;
      case int:
        return intToByteListBE(value);
      case bool:
        return <int>[value ? 1 : 0];
      // case double:
      //   return TODO;
      default:
        throw new Exception('Unknown type $type');
    }
  }

  @override
  toString() {
    dynamic value = field.reflectee;

    return 'Field `$name($type)`=$value';
  }
}
