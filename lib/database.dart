import 'dart:io';
import 'dart:async';
import './utils.dart';

const String INDEX_FILE_NAME = 'index.db';
const String DATABASE_FILE_NAME = 'data.db';
bool noZeroBytes(int byte) => byte != 0;

/**
 * Algorithm of work is simple:
 * 1. Try open database file
 * 1.1. Check if files exists and open them.
 */
class Database {
  final Directory dbPath;
  /// Structure |key 64 byte|offset int32|length int32|
  final File _indexFile;
  final File _database;

  Database(Uri path):
    dbPath = new Directory.fromUri(path),
    _indexFile = new File.fromUri(path.resolve(INDEX_FILE_NAME)),
    _database = new File.fromUri(path.resolve(DATABASE_FILE_NAME));
  
  Future<List<RandomAccessFile>> _prepare() {
    return Future.wait<RandomAccessFile>([
      _indexFile.open(mode: FileMode.APPEND),
      _database.open(mode: FileMode.APPEND),
    ]);
  }

  List<RandomAccessFile> _prepareSync() {
    return <RandomAccessFile>[
      _indexFile.openSync(mode: FileMode.APPEND),
      _database.openSync(mode: FileMode.APPEND),
    ];
  }
  
  Future<List<RandomAccessFile>> _open() async {
    await dbPath.create(recursive: true);

    return _prepare();
  }

  List<RandomAccessFile> _openSync() {
    dbPath.createSync(recursive: true);

    return _prepareSync();
  }

  Future<List<int>> _searchIndexFileForKey(RandomAccessFile indexFile, String key, final int length) async {
    int offset = 0;
    int dataOffset = null;
    int dataLength = null;

    while (offset < length && dataOffset == null) {
      await indexFile.setPosition(offset);
      List<int> bytes = await indexFile.read(64).then((List<int> buffer) => buffer.where(noZeroBytes));
      String bufferKey = new String.fromCharCodes(bytes);

      if (key == bufferKey) {
        List<int> offsetBytes = await indexFile.read(32);
        List<int> lengthBytes = await indexFile.read(32);

        dataOffset = byteListToInt(offsetBytes);
        dataLength = byteListToInt(lengthBytes);
      }
      offset += 128;
    }
    if (dataOffset == null) {
      return null;
    }

    return [dataOffset, dataLength];
  }

  List<int> _searchIndexFileForKeySync(RandomAccessFile indexFile, String key, final int length) {
    int offset = 0;
    int dataOffset = null;
    int dataLength = null;

    while (offset < length && dataOffset == null) {
      indexFile.setPositionSync(offset);
      List<int> bytes = indexFile.readSync(64).where(noZeroBytes);
      String bufferKey = new String.fromCharCodes(bytes);

      if (key == bufferKey) {
        List<int> offsetBytes = indexFile.readSync(32);
        List<int> lengthBytes = indexFile.readSync(32);

        dataOffset = byteListToInt(offsetBytes);
        dataLength = byteListToInt(lengthBytes);
      }
      offset += 128;
    }
    if (dataOffset == null) {
      return null;
    }

    return [dataOffset, dataLength];
  }

  Future _writeKey(RandomAccessFile indexFile, String key, int offset, int size, int length) async {
    List<int> keyBytes = createByteListFromString(key);
    List<int> offsetBytes = intToByteListBE(offset, 32);
    List<int> sizeBytes = intToByteListBE(size, 32);
    List<int> keyBytesWrite = new List<int>.filled(64, 0);

    keyBytesWrite.setAll(0, keyBytes);

    await indexFile.setPosition(length);
    await indexFile.writeFrom(keyBytesWrite);
    await indexFile.writeFrom(offsetBytes);
    await indexFile.writeFrom(sizeBytes);
  }

  void _writeKeySync(RandomAccessFile indexFile, String key, int offset, int size, int length) {
    List<int> keyBytes = createByteListFromString(key);
    List<int> offsetBytes = intToByteListBE(offset, 32);
    List<int> sizeBytes = intToByteListBE(size, 32);
    List<int> keyBytesWrite = new List<int>.filled(64, 0);

    keyBytesWrite.setAll(0, keyBytes);

    indexFile.setPositionSync(length);
    indexFile.writeFromSync(keyBytesWrite);
    indexFile.writeFromSync(offsetBytes);
    indexFile.writeFromSync(sizeBytes);
  }

  /// TODO value should be dynamic (with codecs?)
  /// 1 record can be up to 4Gb length so index is 32byte int
  //? Have third file - meta. contains key increment
  //? Read from index file
  Future put(String key, String value) async {
    List<RandomAccessFile> controlFiles = await _open();
    RandomAccessFile indexFile = controlFiles.first;
    RandomAccessFile databaseFile = controlFiles.last;
    final int length = await indexFile.length();
    final int databaseSize = await databaseFile.length();
    List<int> offsets = await _searchIndexFileForKey(indexFile, key, length);
    final int dataOffset = offsets?.first ?? databaseSize;

    await Future.wait([
      databaseFile.lock(),
      indexFile.lock(),
    ]);

    await databaseFile.setPosition(databaseSize);
    await databaseFile.writeString(value);
    await _writeKey(indexFile, key, dataOffset, value.length, length);

    if (offsets == null) {
      // TODO: clean up
    }

    await Future.wait([
      databaseFile.unlock(),
      indexFile.unlock(),
    ]);
    await Future.wait([
      databaseFile.close(),
      indexFile.close(),
    ]);
  }

  Future putSync(String key, String value) {
    List<RandomAccessFile> controlFiles = _openSync();
    RandomAccessFile indexFile = controlFiles.first;
    RandomAccessFile databaseFile = controlFiles.last;
    final int length = indexFile.lengthSync();
    final int databaseSize = databaseFile.lengthSync();
    List<int> offsets = _searchIndexFileForKeySync(indexFile, key, length);
    final int dataOffset = offsets?.first ?? databaseSize;

    databaseFile.lockSync();
    indexFile.lockSync();

    databaseFile.setPositionSync(databaseSize);
    databaseFile.writeStringSync(value);
    _writeKeySync(indexFile, key, dataOffset, value.length, length);

    if (offsets == null) {
      // TODO: clean up
    }

    databaseFile.unlockSync();
    databaseFile.closeSync();
    indexFile.unlockSync();
    indexFile.closeSync();
  }

  Future<String> get(String key) async {
    List<RandomAccessFile> controlFiles = await _open();
    RandomAccessFile indexFile = controlFiles.first;
    RandomAccessFile database = controlFiles.last;
    final int length = await indexFile.length();
    List<int> offsets = await _searchIndexFileForKey(indexFile, key, length);

    if (offsets?.first == null || offsets?.last == null) {
      throw new Exception("'$key' not found in database");
    }
    final int dataOffset = offsets.first;
    final int dataLength = offsets.last;

    await database.setPosition(dataOffset);
    final List<int> data = await database.read(dataLength);

    database.close();
    indexFile.close();

    return new Future.value(new String.fromCharCodes(data));
  }

  String getSync(String key) {
    List<RandomAccessFile> controlFiles = _openSync();
    RandomAccessFile indexFile = controlFiles.first;
    RandomAccessFile database = controlFiles.last;
    final int length = indexFile.lengthSync();
    List<int> offsets = _searchIndexFileForKeySync(indexFile, key, length);
    
    if (offsets?.first == null || offsets?.last == null) {
      throw new Exception("'$key' not found in database");
    }
    final int dataOffset = offsets.first;
    final int dataLength = offsets.last;

    database.setPositionSync(dataOffset);
    final List<int> data = database.readSync(dataLength);

    database.closeSync();
    indexFile.closeSync();

    return new String.fromCharCodes(data);
  }

  String operator[] (String key) {
    return getSync(key);
  }

  void operator[]= (String key, String value) {
    putSync(key, value);
  }
}
