library dart_database.identifier;

import 'dart:io';
import 'dart:math';
import './utils.dart';

/// process id (2 bytes) - time (4 bytes) - counter (4 byte)
class Identifier {
  static final DateTime _now = new DateTime.now();
  static int _rndOffset = new Random(_now.millisecondsSinceEpoch).nextInt(2147483648);
  final int _increment;
  final DateTime _created;
  final int _processId;

  Identifier():
    _processId = pid,
    _created = _now,
    _increment = (_rndOffset++);
    
  Identifier.fromByteArray(List<int> bytes):
    _processId = byteListToInt(bytes.sublist(0, 2)),
    _created = new DateTime.fromMillisecondsSinceEpoch(byteListToInt(bytes.sublist(2, 6))),
    _increment = byteListToInt(bytes.sublist(6, 10));
    
  List<int> toByteArray() => new List<int>()
    ..addAll(intToByteListBE(_processId, 2))
    ..addAll(intToByteListBE(_created.millisecondsSinceEpoch, 4))
    ..addAll(intToByteListBE(_increment, 4))
    ..toList(growable: false);

  String toString() {
    String pidList = intToByteListBE(_processId, 2).map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    String timeList = intToByteListBE(_created.millisecondsSinceEpoch, 4).map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    String incrementList = intToByteListBE(_increment, 4).map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    
    return '$pidList-$timeList-$incrementList';
  }
}