library dart_database.file_storage;

import 'dart:io';
import 'dart:async';

import 'package:dart_database/dart_database.dart';

class TemporaryAccess<T> {
  T _value;
  Timer _timer;
  final VoidCallback _callback;

  TemporaryAccess(Duration duration, this._value, this._callback) {
    _timer = new Timer(duration, _reset);
  }

  void _reset() {
    _value = null;
    _callback();
  }

  void setTime(Duration time) {
    _timer.cancel();
    _timer = new Timer(time, _reset);
  }

  T get value => _value; 
}

class FileStorage extends Storage {
  static final Map<String, File> _files = new Map();
  final Map<File, TemporaryAccess<RandomAccessFile>> _handlers;
  int _length;
  int _lastPosition;

  FileStorage(String name, {String dbPath}):
  _handlers = new Map(),
  super(name) {
    if (!_files.containsKey(name)) {
      final String path = dbPath ?? Config.get('dbPath') ?? Platform.environment['DB_PATH'] ?? Directory.systemTemp.path;

      _files[name] = new File('$path/$name');
    }
  }

  Future<RandomAccessFile> _open(String name) {
    File file = _files[name];
    TemporaryAccess access = _handlers[file];

    if (access != null && access.value != null) {
      access.setTime(new Duration(seconds: 3));

      return new Future.value(access.value);
    } else {
      return _files[name].open()
        .then((RandomAccessFile fileHandler) {
          _handlers[file] = new TemporaryAccess<RandomAccessFile>(
            new Duration(seconds: 3),
            fileHandler,
            () {
              fileHandler.closeSync();
              _lastPosition = null;
            }
          );

          return fileHandler;
        });
    }
  }

  RandomAccessFile _openSync(String name) {
    File file = _files[name];
    TemporaryAccess access = _handlers[file];
    if (access != null && access.value != null) {
      access.setTime(new Duration(seconds: 3));

      return access.value;
    } else {
      RandomAccessFile fileHandler = _files[name].openSync();

      _handlers[file] = new TemporaryAccess<RandomAccessFile>(
        new Duration(seconds: 3),
        fileHandler,
        () {
          fileHandler.closeSync();
          _lastPosition = null;
        }
      );

      return fileHandler;
    }
  }

  @override
  Future<List<int>> read(int start, [int length = 1]) async {
    RandomAccessFile file = await _open(name);

    if (_lastPosition != start) {
      await file.setPosition(start);
    }
    _lastPosition = (_lastPosition ?? 0) + length;

    return await file.read(length);
  }

  @override
  List<int> readSync(int start, [int length = 1]) {
    RandomAccessFile file = _openSync(name);

    if (_lastPosition != start) {
      file.setPositionSync(start);
    }
    _lastPosition = (_lastPosition ?? 0) + length;

    return file.readSync(length);
  }

  Future<int> write(List<int> buffer, [int offset = null]) async {
    int _offset = offset;
    File file = _files[name];
    RandomAccessFile handler = await file.open(mode: FileMode.writeOnlyAppend);

    if (_offset != null) {
      await handler.setPosition(offset);
    }
    await handler.writeFrom(buffer);
    await handler.close();
    _length = null;
    
    return _files[name].length();
  }

  int writeSync(List<int> buffer, [int offset = null]) {
    int _offset = offset;
    File file = _files[name];
    RandomAccessFile handler = file.openSync(mode: FileMode.writeOnlyAppend);

    if (_offset != null) {
      handler.setPositionSync(offset);
    }
    handler.writeFromSync(buffer);
    handler.closeSync();
    _length = null;

    return size();
  }

  Future clear() async {
    File file = _files[name];

    file.writeAsBytesSync(<int>[], flush: true, mode: FileMode.write);
  }

  @override
  int size() {
    if (_length == null && _files[name].existsSync()) {
      _length = _files[name].lengthSync();
    }
    
    return _length ?? 0;
  }

  @override
  Future<int> readByte(int position) async {
    RandomAccessFile file = await _open(name);
    
    await file.setPosition(position);

    return file.readByte();    
  }

  @override
  int readByteSync(int position) {
    RandomAccessFile file = _openSync(name);
    
    file.setPositionSync(position);

    return file.readByteSync();    
  }
}
