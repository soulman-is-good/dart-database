library dart_database;

export './field.dart';
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
