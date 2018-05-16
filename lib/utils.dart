import 'dart:math';

int sizeOfInt(int number) => (log(number) / log(2) / 8).floor() + 1;

int byteListToInt(List list) {
  int bytes = (list.length - 1) * 8;
  int result = 0;

  list.forEach((int value) {
    result = result | (value << bytes);
    bytes = bytes - 8;
  });

  return result;
}

List<int> intToByteListBE(final int number, [int listSize]) {
  int parsed = number;
  int size = listSize ?? sizeOfInt(number);
  int index = size;
  List<int> list = new List<int>.filled(size, 0);

  if (number == 0) return list;
  while (index > 0) {
    index -= 1;
    list[index] = parsed & 0xff;
    parsed = parsed >> 8;
  }

  return list;
}
