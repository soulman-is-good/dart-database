import 'dart:io';
import 'dart:math';
import 'package:dart_database/dart_database.dart';


class Order extends Entity {
  int get orderId => this['orderId'];
  int get price => this['price'];
  String get title => this['title'];

  Order({
    int price,
    String title,
  }) {
    this['orderId'] = new Random().nextInt(9999998) + 1;
    this['price'] = price;
    this['title'] = title;
  }

  void set price(int value) {
    this['price'] = value;
  }
  void set title(String value) {
    this['title'] = value;
  }
}

void main() {
  bootstrap(
    dbFolder: Platform.script.resolve('../db').toFilePath(),
  );
  Collection<Order> orders = new Collection<Order>(
    builder: () => new Order(),
  );

  orders.clear();

  for(int i = 0; i < 1e3; i ++) {
    orders.add(new Order(price: new Random(i).nextInt(100) + 5, title: 'Order #$i'));
  }
  Order order = orders.elementAt(0);

  print(order);
  print(orders.length);
  print(orders.last);
}
