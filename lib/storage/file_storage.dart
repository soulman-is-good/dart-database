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

  FileStorage(String name):
  _handlers = new Map(),
  super(name) {
    if (!_files.containsKey(name)) {
      final String path = Config.get('dbPath') ?? new String.fromEnvironment('DB_PATH') ?? Directory.systemTemp.path;

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
        }
      );

      return fileHandler;
    }
  }

  @override
  Future<List<int>> read(int start, [int length = 1]) async {
    RandomAccessFile file = await _open(name);

    await file.setPosition(start);

    return await file.read(length);
  }

  @override
  List<int> readSync(int start, [int length = 1]) {
    RandomAccessFile file = _openSync(name);

    file.setPositionSync(start);
    List<int> buffer = file.readSync(length);

    return buffer;
  }

  Future<int> write(List<int> buffer, [int offset = null]) async {
    int _offset = offset;
    File file = _files[name];
    RandomAccessFile handler = await file.open(mode: FileMode.WRITE_ONLY_APPEND);

    if (_offset != null) {
      await handler.setPosition(offset);
    }
    await handler.writeFrom(buffer);
    await handler.close();
    
    return _files[name].length();
  }

  int writeSync(List<int> buffer, [int offset = null]) {
    int _offset = offset;
    File file = _files[name];
    RandomAccessFile handler = file.openSync(mode: FileMode.WRITE_ONLY_APPEND);

    if (_offset != null) {
      handler.setPositionSync(offset);
    }
    handler.writeFromSync(buffer);
    handler.closeSync();

    return size();
  }

  void clear() {
    File file = _files[name];

    file.writeAsBytesSync(<int>[], flush: true, mode: FileMode.WRITE);
  }

  @override
  int size() {
    return _files[name].existsSync() ? _files[name].lengthSync() : 0;
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
