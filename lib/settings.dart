class Settings {
  final String dbPath;

  Settings({this.dbPath});

  dynamic operator [] (String key) {
    switch (key) {
      case 'dbPath':
        return this.dbPath;
      default:
        return null;
    }
  }
}