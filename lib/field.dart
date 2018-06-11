library dart_database.field;

import './utils.dart';

class Field {
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
    int valueLength = byteListToInt(bytes.getRange(valueOffset, valueStart).toList());
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

  static List<int> serialize(String name, dynamic value) => new List<int>()
    ..addAll(_serializeDefinition(name, value))
    ..addAll(_serializeValue(value))
    ..toList(growable: false);

  static List<int> _serializeDefinition(String name, dynamic value) {
    List<int> nameBytes = name.codeUnits;
    int typeByte = _getTypeByte(value);
    List<int> result = new List();
    
    if (nameBytes.length > 255) {
      throw new Exception('field name cannot be larger than 255 symbols');
    }

    result.add(typeByte);
    result.add(nameBytes.length);
    result.addAll(nameBytes);

    return result.toList(growable: false);
  }

  static List<int> _serializeValue(dynamic value) {
    List<int> valueBytes = _valueToByteArray(value);
    List<int> valueLength = intToByteListBE(valueBytes.length, 4);

    return new List<int>()
      ..addAll(valueLength)
      ..addAll(valueBytes)
      ..toList(growable: false);
  }

  static int _getTypeByte(dynamic value) {
    if (value is String) return 0x01;
    if (value is int) return 0x02;
    if (value is bool) return 0x03;

    throw new Exception('Unknown type');
  }

  static List<int> _valueToByteArray(dynamic value) {
    if (value is String) return value.codeUnits;
    if (value is int) return intToByteListBE(value);
    if (value is bool) return <int>[value ? 1 : 0];

    throw new Exception('Unknown type');
  }
}
