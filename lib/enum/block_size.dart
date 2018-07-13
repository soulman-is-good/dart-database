library dart_database.block_size;

class BlockSize {
  final int index;

  const BlockSize(this.index);

  static const BlockSize XXS = const BlockSize(0);
  static const BlockSize XS = const BlockSize(1);
  static const BlockSize S = const BlockSize(2);
  static const BlockSize M = const BlockSize(3);
  static const BlockSize L = const BlockSize(4);
  static const BlockSize XL = const BlockSize(5);
  static const BlockSize XXL = const BlockSize(6);
  static const BlockSize XXXL = const BlockSize(7);

  static const List<BlockSize> values = const <BlockSize>[
    XXS,
    XS,
    S,
    M,
    L,
    XL,
    XXL,
    XXXL,
  ];

  static BlockSize determineBlockSize(int size) {
    // sizes decreased by 6 bytes for block header
    if (size > 1073741818) {
      throw new RangeError.range(size, 0, 1073741818, 'BlockSize', 'Data is too big and currently not supported');
    }
    if (size > 104857594) {
      return XXXL;
    }
    if (size > 10485754) {
      return XXL;
    }
    if (size > 1048570) {
      return XL;
    }
    if (size > 262138) {
      return L;
    }
    if (size > 65530) {
      return M;
    }
    if (size > 16378) {
      return S;
    }
    if (size > 8186) {
      return XS;
    }

    return XXS;
  }

  int get sizeInBytes {
    switch (this) {
      case XXXL:
        return 1073741824;
      case XXL:
        return 104857600;
      case XL:
        return 10485760;
      case L:
        return 1048576;
      case M:
        return 262144;
      case S:
        return 65536;
      case XS:
        return 16384;
      case XXS:
        return 8192;
      default:
        return 0;
    }
  }

  String toString() => {
    0: 'XXS',
    1: 'XS',
    2: 'S',
    3: 'M',
    4: 'L',
    5: 'XL',
    6: 'XXL',
    7: 'XXXL',
  }[index];
}
