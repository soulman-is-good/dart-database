import 'dart:async';

abstract class Storage {
  final String name;
  Storage(this.name);
  Future<List<int>> read(int start, [int length = 1]);
  List<int> readSync(int start, [int length = 1]);
  Future<int> write(List<int> buffer, [int offset = null]);
  int writeSync(List<int> buffer, [int offset = null]);
  int size();
}
