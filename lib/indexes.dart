library dart_database.indexes;

import 'package:dart_database/storage/storage.dart';

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
  final IndexType type;
  final List<String> fieldNames;

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