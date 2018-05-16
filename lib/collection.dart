library dart_database.collection;

import 'dart:mirrors';
import './main.dart';
import './utils.dart';

class _FieldDecorator {
  const _FieldDecorator();
}
const field = const _FieldDecorator();

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
      throw new Exception('Malformed buffer. Name should be more than 2 bytes long');
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

    switch(typeByte) {
      case 0x01:
        fieldValue = new String.fromCharCodes(bytes.getRange(valueStart, valueStart + valueLength));
        break;
      case 0x02:
        fieldValue = byteListToInt(bytes.getRange(valueStart, valueStart + valueLength));
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

class Entity {
  Map<String, Field> _fields;

  Entity() {
    _fields = _parse();
  }
  
  Entity.fromByteArray(List<int> byteArray) {
    _fields = _parse();
    deserialize(byteArray);
  }

  List<int> serialize() {
    List<int> result = new List();

    _fields.forEach((String name, Field field) {
      result.addAll(field.serialize());
    });

    return result;
  }
  
  void deserialize(List<int> byteArray) {
    int offset = 0;
    InstanceMirror im = reflect(this);
    
    while (offset < byteArray.length) {
      dynamic fieldDefSet = Field.parseByteArray(byteArray, offset);
      String fieldName = fieldDefSet[0];
      Field field = _fields.containsKey(fieldName)
        ? _fields[fieldName]
        : null;

      if (field == null || fieldDefSet[1] != field.type) {
        throw new Exception('Datatype missmatch for ${field[0]}');
      }
      Symbol fieldNameSymbol = new Symbol(fieldName);
      dynamic fieldValue = fieldDefSet[2];

      im.setField(fieldNameSymbol, fieldValue);
      offset += fieldDefSet[3];
    }
  }

  List<Field> _parse() {
    InstanceMirror im = reflect(this);
    Map<String, Field> fields = new Map();
    ClassMirror collectionMirror = getCollectionMirror(this.runtimeType);

    if (collectionMirror != null) {
      collectionMirror.declarations.forEach((Symbol fieldName, DeclarationMirror mirror) {
        if (
          mirror is VariableMirror &&
          mirror.metadata.length > 0 &&
          mirror.metadata.first.reflectee is _FieldDecorator
        ) {
          String fieldNameString = MirrorSystem.getName(fieldName);

          im.getField(fieldName);
          fields[fieldNameString] =
            new Field(fieldNameString, mirror.type.reflectedType, im.getField(fieldName));
        }
      });
    }

    return fields;
  }
}

class Collection<T extends Entity> {
  final List<T> entities = new List();

  serialize() {}
  deserialize() {}
}
