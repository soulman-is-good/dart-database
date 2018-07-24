library dart_database.indexes;

import 'dart:collection';

enum IndexType {
    PRIMARY,
    POINTER,
    UNIQUE
}

class IndexPointer {
  int offset;
  dynamic data;
  Index index;
  Storage storage;
}

class Index {
  IndexType type;
  List<String> fieldNames;

  const Index(this.fieldNames, [this.type = IndexType.POINTER]);
}

class PrimaryIndex extends Index {
  const PrimaryIndex(List<String> fieldNames)
    : super(fieldNames, IndexType.PRIMARY);
}

class UniqueIndex extends Index {
  const UniqueIndex(List<String> fieldNames)
    : super(fieldNames, IndexType.UNIQUE);
}