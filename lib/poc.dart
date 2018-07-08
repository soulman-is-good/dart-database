library dart_database.poc;

import 'dart:collection';
import './main.dart';
import './storage/storage.dart';
import './storage/file_storage.dart';
import './utils.dart';

typedef void SaveCallback<S extends Entity>(S item);
typedef S EntityBuilder<S extends Entity>();
typedef S _CursorEntityBuilder<S extends Entity>(int offset, List<int> buffer);

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
  final BlockType blockType;
  final BlockSize blockSize;
  final int position;

  Block([this.position = 0]):
    blockType = BlockType.EMPTY,
    blockSize = BlockSize.S;

  Block.fromByteArray(List<int> bytes, [int offset = 0]):
    blockSize = BlockSize.values[bytes[0]],
    blockType = BlockType.values[bytes[1]],
    position = offset;
    
  Block.forBuffer(List<int> buffer, [int offset = 0]):
    blockSize = determineBlockSize(buffer.length),
    blockType = BlockType.USED,
    position = offset;

  static BlockSize determineBlockSize(int size) {
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

  static int getActualBlockSize(BlockSize size) {
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
    blockSize.index >= determineBlockSize(buffer.length).index;
  
  bool isNotFitFor(List<int> buffer) =>
    blockSize.index < determineBlockSize(buffer.length).index;

  List<int> wrapBuffer(List<int> buffer) {
    if (isNotFitFor(buffer)) {
      throw new Exception('This buffer is no fit for the block. Create a new block.');
    }
    List<int> sizeOfLength = intToByteListBE(buffer.length, 4);

    return new List<int>.filled(size, 0)
      ..setRange(0, 2, [blockSize.index, blockType.index])
      ..setRange(2, 6, sizeOfLength)
      ..setRange(6, buffer.length + 6, buffer);
  }

  int get size => getActualBlockSize(blockSize);
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
    List<int> blockHeader = _storage.readSync(_position, 6);
    BlockSize blockSize = BlockSize.values[blockHeader[0]];
    BlockType blockType = BlockType.values[blockHeader[1]];

    if (blockType != BlockType.USED) {
      _position += Block.getActualBlockSize(blockSize);

      return moveNext();
    }
    int recordLength = byteListToInt(blockHeader.sublist(2, 6));
    List<int> entityData = _storage.readSync(_position + 6, recordLength);

    _current = _creator(_position, entityData);
    _position += Block.getActualBlockSize(blockSize);

    return true;
  }
}

class XCollection<T extends Entity> extends IterableBase<T> {
  final Storage _storage;  
  final String collectionName;
  final EntityBuilder<T> _itemCreator;
  final Map<T, Block> _positionsCache;

  XCollection({Storage storage, EntityBuilder builder, String name}):
    _itemCreator = builder,
    collectionName = name ?? T.toString(),
    _storage = storage ?? new FileStorage(name ?? T.toString()),
    _positionsCache = new Map<T, Block>()
  {
    if (collectionName == 'dynamic') {
      throw new Exception('Specify collection base class derived from Entity');
    }
  }

  T _creator(int position, List<int> buffer) {
    T item = _itemCreator == null ? new Entity() : _itemCreator();

    item.deserialize(buffer);
    item.associatePosition(position);
    item.setSaveCallback(_save);
    _positionsCache[item] = new Block.forBuffer(buffer, position);

    return item;
  }

  void _save(T item) {
    Block block;
    List<int> buffer = item.serialize();
    bool hasItem = _positionsCache.containsKey(item);
    bool isFit = hasItem && _positionsCache[item].isFitFor(buffer);

    if (hasItem) {
      block = _positionsCache[item];
    }

    if (isFit) {
      _storage.writeSync(block.wrapBuffer(buffer), block.position);
      return;
    } else if (hasItem) {
      _storage.writeSync([
        block.blockSize.index,
        BlockType.ABANDONED.index,
      ], block.position);
    }
    // TODO: find available deleted or abandoned block that fits
    int position = _storage.size();

    block = new Block.forBuffer(buffer, position);
    _storage.writeSync(block.wrapBuffer(buffer));
    _positionsCache[item] = block;
  }

  @override
  Iterator<T> get iterator => new Cursor<T>(_creator, _storage);

  void add(T item) {
    _save(item);
    item.setSaveCallback(_save);
  }

  void remove(T item) {
    if (_positionsCache.containsKey(item)) {
      Block block = _positionsCache[item];

      _storage.writeSync([
        block.blockSize.index,
        BlockType.DELETED.index,
      ], block.position);
    }
  }

  void removeAt(int index) {
    T item = elementAt(index);

    remove(item);
  }

  List<Block> getBlocks() {
    int size = _storage.size();
    int position = 0;
    List<Block> blocks = new List<Block>();

    while (position < size) {
      List<int> header = _storage.readSync(position, 2);
      Block block = new Block.fromByteArray(header, position);

      blocks.add(block);
      position += block.size;
    }

    return blocks;
  }

  void optimize() {
    _storage.lockSync();
    // TODO: remove deleted and abandoned blocks
    _storage.unlockSync();
  }
}
