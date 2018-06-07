import 'dart:mirrors';
import 'dart:collection';
import './main.dart';
import './storage/file_storage.dart';
import './utils.dart';

class Cursor<T extends Entity> extends Iterator<T> {
  FileStorage _storage;
  int _position;
  T _current;

  Cursor() {
    TypeMirror mirror = reflectType(T);
    String name = MirrorSystem.getName(mirror.simpleName);

    _storage = new FileStorage(name);
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
    TypeMirror mirror = reflectType(T);
    ClassMirror classMirror = reflectClass(mirror.reflectedType);
    List<int> recordLengthBytes = _storage.readSync(_position, 4);
    int recordLength = byteListToInt(recordLengthBytes);
    List<int> entityData = _storage.readSync(_position + 4, recordLength);
    Symbol byteArrayConstuctor = new Symbol('fromByteArray');

    _position += recordLength + 4;
    _current = classMirror.newInstance(byteArrayConstuctor, [entityData]).reflectee;

    return true;
  }
}

class XCollection<T extends Entity> extends IterableBase<T> {
  /// Order - buffer/file offset
  /// TODO: Maybe implement static data length to not to resize all the data in the file
  /// TODO: ===> OR!!! add some revision property and when entity updates - write it in the end of file as new then clean up someday
  // Map<T, int> _collection = new Map();

  @override
  Iterator<T> get iterator => new Cursor<T>();
}
