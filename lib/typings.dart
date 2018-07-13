library dart_database.typings;

import 'package:dart_database/dart_database.dart';

typedef void VoidCallback();
typedef void SaveCallback<S extends Entity>(S item);
typedef S EntityBuilder<S extends Entity>();
