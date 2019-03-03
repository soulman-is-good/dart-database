library dart_database.block;

import 'package:dart_database/block_reader.dart';
import 'package:dart_database/dart_database.dart';
import 'package:dart_database/utils.dart';

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
    List<int> sizeOfLength = intToByteListBE(buffer.length, BlockReader.lengthSize);

    return new List<int>.filled(size, 0)
      ..setRange(0, BlockReader.paramsSize, [blockSize.index, blockType.index])
      ..setRange(BlockReader.paramsSize, BlockReader.headerSize, sizeOfLength)
      ..setRange(BlockReader.headerSize, buffer.length + BlockReader.headerSize, buffer);
  }

  int get size => blockSize.sizeInBytes;
}
