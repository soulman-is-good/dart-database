library dart_database.entity;

import 'dart:collection';
import './main.dart';

abstract class Entity extends MapBase {
  int _position;
  final Map<String, dynamic> _fields = new Map();
  VoidCallback saveCallback;

  Entity();  
  Entity.fromByteArray(List<int> byteArray) {
    deserialize(byteArray);
  }

  List<int> serialize() {
    List<int> result = new List();

    _fields.forEach((String name, dynamic value) {
      result.addAll(Field.serialize(name, value));
    });

    return result;
  }
  
  void deserialize(List<int> byteArray) {
    int offset = 0;
    
    while (offset < byteArray.length) {
      List fieldDefSet = Field.parseByteArray(byteArray, offset);
      String fieldName = fieldDefSet[0];
      dynamic fieldValue = fieldDefSet[2];

      _fields[fieldName] = fieldValue;
      offset = fieldDefSet[3];
    }
  }
  
  void setSaveCallback(VoidCallback callback) {
    saveCallback = callback;
  }
  
  void associatePosition(int position) {
    _position = position;
  }

  @override
  operator [](Object key) {
    return _fields[key];
  }

  @override
  void operator []=(key, value) {
    _fields[key] = value;
  }

  @override
  void clear() {
    _fields.clear();
  }

  @override
  Iterable get keys => _fields.keys;

  @override
  remove(Object key) {
    _fields.remove(key);
  }
  
  void save() {
    if (saveCallback != null) {
      saveCallback(this);
    }
  }
  
  @override
  bool operator ==(dynamic o) => o is Entity && hashCode == o.hashCode;

  @override
  int get hashCode => _position ?? super.hashCode;
}
