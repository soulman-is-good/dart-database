import 'dart:async';
import './storage.dart';

class MemoryStorage extends Storage {
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

  @override
  Future<int> write(List<int> buffer, [int offset = null]) {
    // TODO: implement write
  }

  @override
  int writeSync(List<int> buffer, [int offset = null]) {
    // TODO: implement writeSync
  }
}
