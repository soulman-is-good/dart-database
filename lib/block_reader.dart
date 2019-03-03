class BlockReader {
  static final int paramsSize = 2;
  static final int lengthSize = 4;
  static final int headerSize = 6;

  static List<int> readHeader(List<int> buffer, [int offset = 0]) {
    return buffer.sublist(offset, offset + headerSize).toList();
  }

  static List<int> readBlockParameters(List<int> buffer, [int offset = 0]) {
    return buffer.sublist(offset, offset + paramsSize).toList();
  }

  static List<int> readBufferLength(List<int> buffer, [int offset = 0]) {
    return buffer.sublist(offset + paramsSize, offset + headerSize).toList();
  }
}