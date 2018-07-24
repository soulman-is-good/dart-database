library dart_database.identifier;

import 'dart:io';
import 'dart:math';
import './utils.dart';

const FOUR_BYTES = 4294967296;

/// process id (2 bytes) - time (6 bytes) - counter (4 byte)
class Identifier {
  static int _rndOffset = new Random(new DateTime.now().millisecondsSinceEpoch).nextInt(FOUR_BYTES);
  final int _increment;
  final DateTime _created;
  final int _processId;

  Identifier():
    _processId = pid,
    _created = new DateTime.now(),
    _increment = _rndOffset
  {
    _rndOffset = (_rndOffset + 1) % FOUR_BYTES;
  }
    
  Identifier.fromByteArray(List<int> bytes):
    _processId = byteListToInt(bytes.sublist(0, 2)),
    _created = new DateTime.fromMillisecondsSinceEpoch(byteListToInt(bytes.sublist(2, 8))),
    _increment = byteListToInt(bytes.sublist(8, 12));
    
  List<int> toByteArray() => new List<int>()
    ..addAll(intToByteListBE(_processId, 2))
    ..addAll(intToByteListBE(_created.millisecondsSinceEpoch, 6))
    ..addAll(intToByteListBE(_increment, 4))
    ..toList(growable: false);

  String toString() {
    String pidList = intToByteListBE(_processId, 2).map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    String timeList = intToByteListBE(_created.millisecondsSinceEpoch, 6).map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    String incrementList = intToByteListBE(_increment, 4).map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    
    return '$pidList-$timeList-$incrementList';
  }
  
  @override
  bool operator ==(dynamic o) => o is Identifier && hashCode == o.hashCode;

  @override
  int get hashCode {
    List<int> bytes = toByteArray();

    return byteListToInt(bytes);
  }
}