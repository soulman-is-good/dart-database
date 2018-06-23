import 'dart:collection';
import './main.dart';
import './storage/storage.dart';
import './storage/file_storage.dart';
import './utils.dart';

typedef void SaveCallback<S extends Entity>(S item);
typedef S EntityBuilder<S extends Entity>();
typedef S _CursorEntityBuilder<S extends Entity>(int offset);

enum BlockSize {
  XXS, // 8KB
  XS, // 16KB
  S, // 64KB
  M, // 256KB
  L, // 1MB
  XL, // 10MB
  XXL, // 100MB
  XXXL, // 1GB
}

class Cursor<T extends Entity> extends Iterator<T> {
  final _CursorEntityBuilder<T> _creator;
  final Storage _storage;
  int _position;
  T _current;

  Cursor(this._creator, this._storage) {
    _position = 0;
    _current = null;
  }

  @override
  T get current => _current;

  @override
  bool moveNext() {
    if (_position >= _storage.size()) {
      return false;
    }
    List<int> recordLengthBytes = _storage.readSync(_position, 4);
    int recordLength = byteListToInt(recordLengthBytes);
    List<int> entityData = _storage.readSync(_position + 4, recordLength);

    _current = _creator(_position);
    _position += recordLength + 4;
    _current.deserialize(entityData);

    return true;
  }
}

class XCollection<T extends Entity> extends IterableBase<T> {
  final FileStorage _storage;  
  final String collectionName;
  final EntityBuilder<T> _itemCreator;
  final Map<T, int> _positionsCache;

  XCollection(this.collectionName, this._itemCreator): _storage = new FileStorage(collectionName);
  /// Order - buffer/file offset
  /// TODO: Maybe implement static data length to not to resize all the data in the file
  /// TODO: ===> OR!!! add some revision property and when entity updates - write it in the end of file as new then clean up someday
  // Map<T, int> _collection = new Map();

  T _creator(int position) {
    T item = _itemCreator();
    _positionsCache[item] = position;

    return item;
  }

  void _save(T item) {
    int offset = _positionsCache[item];

  }

  @override
  Iterator<T> get iterator => new Cursor<T>(_creator, _storage);

  void save() {
  }
}
