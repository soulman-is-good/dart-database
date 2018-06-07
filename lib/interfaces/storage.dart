import 'dart:async';

abstract class StorageInterface {
  final String name;
  StorageInterface(this.name);
  Future<List<int>> read(int start, [int length = 1]);
  List<int> readSync(int start, [int length = 1]);
  int size();
}
