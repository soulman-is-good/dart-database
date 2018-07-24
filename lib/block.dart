library dart_database.block;

import 'package:dart_database/dart_database.dart';

class Block {
  final BlockType blockType;
  final BlockSize blockSize;
  final int position;
  final Block previous;

  Block([this.position = 0, this.previous]):
    blockType = BlockType.EMPTY,
    blockSize = BlockSize.S;

  Block.fromByteArray(List<int> bytes, [int offset = 0, this.previous]):
    blockSize = BlockSize.values[bytes[0]],
    blockType = BlockType.values[bytes[1]],
    position = offset;
    
  Block.forBuffer(List<int> buffer, [int offset = 0]):
    blockSize = BlockSize.determineBlockSize(buffer.length),
    blockType = BlockType.USED,
    position = offset;
  
  bool isFitFor(List<int> buffer) =>
    blockSize.index >= BlockSize.determineBlockSize(buffer.length).index;
  
  bool isNotFitFor(List<int> buffer) =>
    blockSize.index < BlockSize.determineBlockSize(buffer.length).index;

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

  int get size => blockSize.sizeInBytes;
}
