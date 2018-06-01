library dart_database.collection;

import 'dart:collection';

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
  
  @override
  void addAll(List<T> items) {
    _items.addAll(items);
  }

  List<int> serialize() {
    List<int> result = new List();

    this.forEach((T item) {
      result.addAll(item.serialize());
    });

    return result.toList(growable: false);
  }
}
