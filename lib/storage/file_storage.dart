import 'dart:io';
import 'dart:async';
import '../main.dart';
import '../interfaces/storage.dart';

class FileStorage extends StorageInterface {
  static final Map<String, File> _files = new Map();

  FileStorage(String name): super(name) {
    if (!_files.containsKey(name)) {
      final String path = Config.get('dbPath');

      _files[name] = new File('$path/$name.db');
    }
  }

  @override
  Future<List<int>> read(int start, [int length = 1]) async {
    RandomAccessFile file = await _files[name].open();

    await file.setPosition(start);

    return await file.read(length);
  }

  @override
  List<int> readSync(int start, [int length = 1]) {
    RandomAccessFile file = _files[name].openSync();

    file.setPositionSync(start);

    return file.readSync(length);
  }

  @override
  int size() {
    return _files[name].lengthSync();
  }
}
