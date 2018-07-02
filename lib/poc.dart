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
class BlockType {
  final int index;

  const BlockType(this.index);

  static const BlockType EMPTY = const BlockType(0);
  static const BlockType USED = const BlockType(1);
  static const BlockType DELETED = const BlockType(2);
  static const BlockType ABANDONED = const BlockType(3);

  static const List<BlockType> values = const <BlockType>[
    EMPTY,
    USED,
    DELETED,
    ABANDONED,
  ];
  String toString() => {
    0: EMPTY,
    1: USED,
    2: DELETED,
    3: ABANDONED,
  }[index];
}

class Block {
  final BlockType type;
  final BlockSize size;
  final int position;
  final int _dataLength;

  Block():
    type = BlockType.EMPTY,
    size = BlockSize.S;

  Block.fromByteArray(List<int> buffer, [int offset = 0]):
    size = BlockSize.values[buffer[0]],
    type = BlockType.values[buffer[1]],
    position = offset,
    _dataLength = buffer.length;
    
  Block.forBuffer(List<int> buffer, [int offset = 0]):
    size = _determineBlockSize(buffer.length),
    type = BlockType.USED,
    position = offset,
    _dataLength = buffer.length;

  static BlockSize _determineBlockSize(int size) {
    // sizes decreased by 6 bytes for block header
    if (size > 1073741818) {
      throw new RangeError.range(size, 0, 1073741818, 'BlockSize', 'Data is too big and currently not supported');
    }
    if (size > 104857594) {
      return BlockSize.XXXL;
    }
    if (size > 10485754) {
      return BlockSize.XXL;
    }
    if (size > 1048570) {
      return BlockSize.XL;
    }
    if (size > 262138) {
      return BlockSize.L;
    }
    if (size > 65530) {
      return BlockSize.M;
    }
    if (size > 16378) {
      return BlockSize.S;
    }
    if (size > 8186) {
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
  
  bool isFitFor(List<int> buffer) =>
    size.index >= _determineBlockSize(buffer.length).index;
  
  bool isNotFitFor(List<int> buffer) =>
    size.index < _determineBlockSize(buffer.length).index;

  List<int> wrapBuffer(List<int> buffer) {
    if (isNotFitFor(buffer)) {
      throw new Exception('This buffer is no fit for the block. Create a new block.');
    }
    List<int> sizeOfLength = intToByteListBE(buffer.length, 4);
    int blockSize = _getActualBlockSize(size);

    return new List<int>.filled(blockSize, 0)
      ..setRange(0, 2, [size.index, type.index])
      ..setRange(2, 6, sizeOfLength)
      ..setRange(6, buffer.length + 6, buffer);
  }

  int get blockSize {
    BlockSize blockSize = _determineBlockSize(buffer.length);

    return _getActualBlockSize(blockSize);
  }
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
  final Map<T, Block> _positionsCache;

  XCollection({Storage storage, EntityBuilder builder, String name}):
    collectionName = name ?? T.toString(),
    _itemCreator = builder,
    _storage = storage ?? new FileStorage(name ?? T.toString()),
    _positionsCache = new Map<T, Block>()
  {
    if (collectionName == 'dynamic') {
      throw new Exception('Specify collection base class derived from Entity');
    }
  }

  T _creator(int position) {
    T item = _itemCreator();
    item.associatePosition(position);
    _positionsCache[item] = position;
    item.setSaveCallback(_save);

    return item;
  }

  void _save(T item) {
    Block block;
    int position;
    List<int> buffer = item.serialize();

    if (_positionsCache.containsKey(item) && _positionsCache[item].isFitFor(buffer)) {
      block = _positionsCache[item];
      position = block.position;

      _storage.writeSync(block.wrapBuffer(buffer), position);
    } else {
      position = _storage.size();
      block = new Block.forBuffer(buffer, position);
      _storage.writeSync(block.wrapBuffer(buffer));
      _positionsCache[item] = block;
    }
  }

  @override
  Iterator<T> get iterator => new Cursor<T>(_creator, _storage);

  void add(T item) {
    _save(item);
    item.setSaveCallback(_save);
  }
}
