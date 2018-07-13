library dart_database.block_type;

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
    0: 'EMPTY',
    1: 'USED',
    2: 'DELETED',
    3: 'ABANDONED',
  }[index];
}
