library dart_database.entity;

import 'dart:mirrors';
import './main.dart';

class _FieldDecorator {
  const _FieldDecorator();
}
const field = const _FieldDecorator();

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
      List fieldDefSet = Field.parseByteArray(byteArray, offset);
      String fieldName = fieldDefSet[0];
      Field field = _fields.containsKey(fieldName)
        ? _fields[fieldName]
        : null;

      if (field == null || fieldDefSet[1] != field.type) {
        throw new Exception('Datatype missmatch for ${fieldName}');
      }
      Symbol fieldNameSymbol = new Symbol(fieldName);
      dynamic fieldValue = fieldDefSet[2];

      im.setField(fieldNameSymbol, fieldValue);
      offset = fieldDefSet[3];
    }
  }

  Map<String, Field> _parse() {
    InstanceMirror im = reflect(this);
    Map<String, Field> fields = new Map();
    ClassMirror collectionMirror = Config.getCollectionMirror(this.runtimeType);

    if (collectionMirror == null) {
      throw new Exception('Could not find class ${MirrorSystem.getName(im.type.simpleName)}. Have you run bootstrap?');
    }
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

    return fields;
  }
}
