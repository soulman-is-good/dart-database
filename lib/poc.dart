import 'dart:io';
import 'dart:async';
import 'dart:collection';

class MemoryStorage extends StorageInterface {
  static final Map<String, List<int>> _store = new Map();

  MemoryStorage(String name): super(name) {
    _store[name] = new List();
  }

  @override
  Stream<List<int>> read() {
    return new Stream.fromIterable(_store[name]);
  }
}

final String path = '../';

class FileStorage extends StorageInterface {
  static final Map<String, File> _files = new Map();

  FileStorage(String name): super(name) {
    _files[name] = new File('$path/$name.db');
  }

  @override
  Stream<List<int>> read() {
    return _files[name].openRead();
  }
}

abstract class StorageInterface {
  final String name;
  StorageInterface(this.name);
  Stream read();
}

class Cursor<T> extends Iterator<T> {
  // TODO: implement current
  @override
  T get current => null;

  @override
  bool movePrevious() {
    // TODO: implement movePrevious
  }
}

class Collection<T> extends IterableBase<T> {
  /// Order - buffer/file offset
  /// TODO: Maybe implement static data length to not to resize all the data in the file
  /// TODO: ===> OR!!! add some revision property and when entity updates - write it in the end of file as new then clean up someday
  Map<Entity, int> _collection = new Map();

  @override
  Iterator<T> get iterator => null;
}
