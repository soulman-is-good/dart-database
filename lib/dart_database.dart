library dart_database;

import 'package:dart_database/settings.dart';

export './enum/block_size.dart';
export './enum/block_type.dart';
export './storage/file_storage.dart';
export './storage/memory_storage.dart';
export './storage/storage.dart';
export './typings.dart';
export './field.dart';
export './block.dart';
export './cursor.dart';
export './entity.dart';
export './collection.dart';

/// Database properties
/// - dbPath: string
Settings _settings;

void bootstrap({String dbFolder}) {
  _settings = new Settings(
    dbPath: dbFolder,
  );
}

/// Exported

class Config {
  static dynamic get(String name) => _settings[name];
}
