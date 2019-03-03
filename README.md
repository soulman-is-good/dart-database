# Dart database

Embeded database built in on Dart.

**This package is still under development and will heavily change. Use on your own risk**

### How to use?

All operations are syncronous and reflects the status at disk

```dart
import 'package:dart_database/dart_database.dart';

class Item extends Entity {}

void main() {
  bootstrap(
    dbFolder: Platform.script.resolve('./db').toFilePath(),
  );
  Collection<Item> items = new Collection<Item>(
    builder: () => new Item(),
  );
  Item item = new Item();

  item['id'] = 1;
  item['title'] = 'New item';
  items.add(item);
}

```
