library dart_database;

import 'dart:mirrors';
import './entity.dart';

export './field.dart';
export './entity.dart';
export './collection.dart';

final Map<Type, ClassMirror> _collectionsMirrors = new Map();
/// Database properties
/// - dbPath: string
final Map<String, dynamic> _settings = new Map();

void bootstrap(Map<String, dynamic> settings) {
  MirrorSystem ms = currentMirrorSystem();

  _settings.addAll(settings);
  ms.libraries.forEach((Uri uri, LibraryMirror lib) {
    lib.declarations.forEach((Symbol className, DeclarationMirror mirror) {
      if (mirror is ClassMirror && mirror.superclass != null && mirror.superclass.reflectedType == Entity) {
        _collectionsMirrors[mirror.reflectedType] = mirror;
      }
    });
  });
}

/// Exported

class Config {
  static ClassMirror getCollectionMirror(Type collection) => _collectionsMirrors[collection];
  static dynamic get(String name) => _settings[name];
}
