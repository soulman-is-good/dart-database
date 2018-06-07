import 'dart:async';
import '../interfaces/storage.dart';

class MemoryStorage extends StorageInterface {
  static final Map<String, List<int>> _store = new Map();

  MemoryStorage(String name): super(name) {
    _store[name] = new List();
  }

  @override
  Future<List<int>> read(int start, [int length = 1]) {
    return new Future.value(_store[name].sublist(start, start + length));
  }

  @override
  List<int> readSync(int start, [int length = 1]) {
    return _store[name].sublist(start, start + length);
  }

  @override
  int size() {
    return _store[name].length;
  }
}
