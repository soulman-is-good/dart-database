library dart_database.collection;

import 'dart:collection';

import 'package:dart_database/block_reader.dart';
import 'package:dart_database/dart_database.dart';
import 'package:dart_database/utils.dart';
import 'package:meta/meta.dart';

class Collection<T extends Entity> extends IterableBase<T> {
  final Storage _storage;  
  final String collectionName;
  final EntityBuilder<T> _itemCreator;
  final Expando<Block> _positionsCache;
  final Storage _indexFile;
  final List<String> _indexFields;

  Collection({
    @required EntityBuilder builder,
    Storage storage,
    String name,
    List<String> indexes,
    Storage indexStorage,
  }):
    _itemCreator = builder,
    collectionName = name ?? T.toString(),
    _storage = storage ?? new FileStorage('${name ?? T.toString()}.db'),
    _positionsCache = new Expando<Block>(name ?? T.toString()),
    _indexFields = indexes ?? <String>['_id'],
    _indexFile = indexStorage ?? new FileStorage('${name ?? T.toString()}.idx')
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
    bool hasItem = _positionsCache[item] != null;
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

  @override
  T elementAt(int index) {
    int size = _storage.size();
    int position = 0;
    int currentIndex = 0;
    List<int> header;

    while (position < size && currentIndex <= index) {
      header = _storage.readSync(position, BlockReader.headerSize);
      BlockSize blockSize = BlockSize.values[header[0]];

      position += blockSize.sizeInBytes;
      currentIndex += 1;
    }

    if (position >= size) {
      throw new RangeError.index(index, []);
    }
    int dataSize = byteListToInt(BlockReader.readBufferLength(header));
    List<int> buffer = _storage.readSync(position + BlockReader.headerSize, dataSize);

    return _creator(position, buffer);
  }

  void add(T item) {
    _save(item);
    item.setSaveCallback(_save);
  }

  void remove(T item) {
    if (_positionsCache[item] != null) {
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
    // TODO: remove deleted and abandoned blocks
  }

  void clear() {
    _storage.clear();
  }
}
