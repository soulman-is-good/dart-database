library dart_database;

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
final Map<String, dynamic> _settings = new Map();

void bootstrap(Map<String, dynamic> settings) {
  _settings.addAll(settings);
}

/// Exported

class Config {
  static dynamic get(String name) => _settings[name];
}
