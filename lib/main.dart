library dart_database;

import 'dart:mirrors';
import './collection.dart';

export './collection.dart';

Map<Type, ClassMirror> _collectionsMirrors = new Map();

void bootstrap() {
  MirrorSystem ms = currentMirrorSystem();

  ms.libraries.forEach((Uri uri, LibraryMirror lib) {
    lib.declarations.forEach((Symbol className, DeclarationMirror mirror) {
      if (mirror is ClassMirror && mirror.superclass != null && mirror.superclass.reflectedType == Entity) {
        _collectionsMirrors[mirror.reflectedType] = mirror;
      }
    });
  });
}

ClassMirror getCollectionMirror(Type collection) => _collectionsMirrors[collection];
