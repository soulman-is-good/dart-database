library dart_database.identifier;

import 'dart:io';
import 'dart:math';
import './utils.dart';

/// process id (2 bytes) - time (4 bytes) - counter (4 byte)
class Identifier {
  static final DateTime _now = new DateTime.now();
  static int _rndOffset = new Random(_now.millisecondsSinceEpoch).nextInt(2147483648);
  final int _increment;

  Identifier():
    _increment = (_rndOffset++);
    
  List<int> toByteArray() => new List<int>()
    ..addAll(intToByteListBE(pid, 2))
    ..addAll(intToByteListBE(_now.millisecondsSinceEpoch, 4))
    ..addAll(intToByteListBE(_increment, 4))
    ..toList(growable: false);

  String toString() {
    String pidList = intToByteListBE(pid, 2).map((int byte) => byte.toRadixString(16)).join('');
    String timeList = intToByteListBE(_now.millisecondsSinceEpoch, 4).map((int byte) => byte.toRadixString(16)).join('');
    String incrementList = intToByteListBE(_increment, 4).map((int byte) => byte.toRadixString(16)).join('');
    
    return '$pidList-$timeList-$incrementList';
    // return toByteArray().map((int byte) => byte.toRadixString(16)).join('');
  }
}