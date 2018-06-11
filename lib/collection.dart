library dart_database.collection;

import 'dart:collection';
import './entity.dart' show Entity;
import './utils.dart';

class Collection<T extends Entity> extends ListBase<T> {
  final List<T> _items = <T>[];

  @override
  int get length => _items.length;

  @override
  T operator [](int index) => _items[index];

  @override
  void operator []=(int index, T value) {
    _items[index] = value;
  }
  
  @override
  void add(T item) {
    _items.add(item);
  }

  List<int> serialize() {
    List<int> result = new List();

    this.forEach((T item) {
      List<int> data = item.serialize();
      int length = data.length;
      List<int> lengthBytes = intToByteListBE(length, 4);

      result.addAll(lengthBytes);
      result.addAll(data);
    });

    return result.toList(growable: false);
  }

  @override
  set length(int newLength) {
    _items.length = newLength;
  }
}
