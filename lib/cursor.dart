library dart_database.cursor;

import 'package:dart_database/dart_database.dart';
import './utils.dart';

typedef S _CursorEntityBuilder<S extends Entity>(int offset, List<int> buffer);

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
      _position += blockSize.sizeInBytes;

      return moveNext();
    }
    int recordLength = byteListToInt(blockHeader.sublist(2, 6));
    List<int> entityData = _storage.readSync(_position + 6, recordLength);

    _current = _creator(_position, entityData);
    _position += blockSize.sizeInBytes;

    return true;
  }
  
  // implement elementAt and other functions with _indexes
}
