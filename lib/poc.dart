library dart_database.poc;

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
enum BlockType {
  FREE,
  OCCUPIED,
}

class Block {
  final List<int> buffer;
  BlockType type;
  BlockSize size;
  int dataLength = 0;

  Block(this.buffer, [BlockType type]);

  factory Block.parse(List<int> buffer) {
    BlockSize blockSize = (buffer[0] & 0x0f) as BlockSize;
    BlockType blockType = ((buffer[0] & 0xf0) >> 4) as BlockType;
    int dataSize = byteListToInt(buffer.sublist(1, 4));
    List<int> dataBuffer = buffer.sublist(5, dataSize);

    return new Block(dataBuffer)
      ..type = blockType
      ..size = blockSize;
  }

  static int getSizeOfBlock(List<int> buffer) {
    BlockSize blockSize = (buffer[0] & 0x0f) as BlockSize;

    return _getActualBlockSize(blockSize);
  }

  static BlockSize _determineBlockSize(int size) {
    if (size > 1073741824) {
      throw new RangeError.range(size, 0, 1073741824, 'BlockSize', 'Block size is too big');
    }
    if (size > 104857600) {
      return BlockSize.XXXL;
    }
    if (size > 10485760) {
      return BlockSize.XXL;
    }
    if (size > 1048576) {
      return BlockSize.XL;
    }
    if (size > 262144) {
      return BlockSize.L;
    }
    if (size > 65536) {
      return BlockSize.M;
    }
    if (size > 16384) {
      return BlockSize.S;
    }
    if (size > 8192) {
      return BlockSize.XS;
    }

    return BlockSize.XXS;
  }

  static int _getActualBlockSize(BlockSize size) {
    switch (size) {
      case BlockSize.XXXL:
        return 1073741824;
      case BlockSize.XXL:
        return 104857600;
      case BlockSize.XL:
        return 10485760;
      case BlockSize.L:
        return 1048576;
      case BlockSize.M:
        return 262144;
      case BlockSize.S:
        return 65536;
      case BlockSize.XS:
        return 16384;
      case BlockSize.XXS:
        return 8192;
      default:
        return 0;
    }
  }

  List<int> getBytes() {
    List<int> sizeOfLength = intToByteListBE(buffer.length, 4);
    BlockSize blockSize = _determineBlockSize(buffer.length);
    int blockType = BlockType.OCCUPIED.index << 4;
    List<int> filler = new List.filled(_getActualBlockSize(blockSize) - buffer.length, 0);
    
    return new List()
      ..add(blockType | blockSize.index)
      ..addAll(sizeOfLength)
      ..addAll(buffer)
      ..addAll(filler)
      ..toList(growable: false);
  }

  int get blockSize {
    BlockSize blockSize = _determineBlockSize(buffer.length);

    return _getActualBlockSize(blockSize);
  }

  int get dataSize => buffer.length;
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
    List<int> blockHeader = _storage.readSync(_position, 5);
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
  final Storage _storage;  
  final String collectionName;
  final EntityBuilder<T> _itemCreator;
  final Map<T, int> _positionsCache;

  XCollection(this.collectionName, this._itemCreator, {Storage storage}):
    _storage = storage ?? new FileStorage(collectionName),
    _positionsCache = new Map();

  T _creator(int position) {
    T item = _itemCreator();
    item.associatePosition(position);
    _positionsCache[item] = position;
    item.setSaveCallback(_save);

    return item;
  }

  void _save(T item) {
    int offset = _positionsCache[item];
    List<int> data = item.serialize();
    int newSize = _storage.writeSync(data, offset);
    int position = newSize - data.length;

    _positionsCache[item] = position;
    item.associatePosition(position);
  }

  @override
  Iterator<T> get iterator => new Cursor<T>(_creator, _storage);

  void add(T item) {
    _save(item);
    item.setSaveCallback(_save);
  }
}
