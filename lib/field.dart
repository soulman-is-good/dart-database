library dart_database.field;

import 'package:dart_database/dart_database.dart';
import './utils.dart';

enum FieldType {
  IDENTIFIER,
  STRING,
  INTEGER,
  BOOLEAN
}

class Field {
  static dynamic parseByteArray(List<int> byteList, [int offset = 0]) {
    List<int> bytes = byteList.sublist(offset);
    Type fieldType;
    FieldType typeByte = FieldType.values[bytes[0]];

    if (bytes.length < 3) {
      throw new Exception('Malformed buffer. Field should be more than 2 bytes long');
    }
    switch(typeByte) {
      case FieldType.IDENTIFIER:
        fieldType = Identifier;
        break;
      case FieldType.STRING:
        fieldType = String;
        break;
      case FieldType.INTEGER:
        fieldType = int;
        break;
      case FieldType.BOOLEAN:
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
    List<int> dataBuffer = bytes.getRange(valueStart, valueStart + valueLength).toList();

    switch(typeByte) {
      case FieldType.IDENTIFIER:
        fieldValue = new Identifier.fromByteArray(dataBuffer);
        break;
      case FieldType.STRING:
        fieldValue = new String.fromCharCodes(dataBuffer);
        break;
      case FieldType.INTEGER:
        fieldValue = byteListToInt(dataBuffer);
        break;
      case FieldType.BOOLEAN:
        fieldValue = bytes[valueStart] == 1;
        break;
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
    if (value is Identifier) return FieldType.IDENTIFIER.index;
    if (value is String) return FieldType.STRING.index;
    if (value is int) return FieldType.INTEGER.index;
    if (value is bool) return FieldType.BOOLEAN.index;

    throw new Exception('Unknown type ${value.runtimeType.toString()}');
  }

  static List<int> _valueToByteArray(dynamic value) {
    if (value is Identifier) return value.toByteArray();
    if (value is String) return value.codeUnits;
    if (value is int) return intToByteListBE(value);
    if (value is bool) return <int>[value ? 1 : 0];

    throw new Exception('Unknown type');
  }
}
