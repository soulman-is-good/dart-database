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
  final int length;
  dynamic value;

  Field(this.name, this.type):;

  List<int> serializeDefinition() {
    List<int> nameBytes = name.codeUnits;
    int typeByte = _getTypeByte();
    List<int> result = new List();

    result.add(typeByte);
    result.addAll(nameBytes);

    return result.toList(growable: false);
  }

  List<int> serializeValue() {
    List<int> valueBytes = _valueToByteArray();

    return valueBytes.toList(growable: false);
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
    switch (type) {
      case String:
        return (value as String).codeUnits;
      case int:
        return intToByteListBE(value);
      case bool:
        return value ? 1 : 0;
      // case double:
      //   return TODO;
      default:
        throw new Exception('Unknown type $type');
    }
  }

  @override
  toString() {
    return 'Field `$name($type)`=$value';
  }
}

class Entity {
  List<Field> serialize() {
    InstanceMirror im = reflect(this);
    List<Field> fields = new List();
    ClassMirror collectionMirror = getCollectionMirror(this.runtimeType);

    if (collectionMirror != null) {
      collectionMirror.declarations.forEach((Symbol fieldName, DeclarationMirror mirror) {
        if (mirror is VariableMirror && mirror.metadata.length > 0 && mirror.metadata.first.reflectee is _FieldDecorator) {
          String fieldNameString = MirrorSystem.getName(fieldName);

          fields.add(new Field(fieldNameString, mirror.type.reflectedType, im.getField(fieldName).reflectee));
        }
      });
    }

    return fields;
  }
}

class Collection<T extends Entity> {
  final List<T> entities = new List();

  serialize() {

  }
}
