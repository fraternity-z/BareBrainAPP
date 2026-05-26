import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

typedef ReadString = Future<String?> Function(String key);
typedef WriteString = Future<void> Function(String key, String value);
typedef RemoveString = Future<void> Function(String key);

class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore({
    SharedPreferencesAsync? preferences,
    ReadString? readString,
    WriteString? writeString,
    RemoveString? removeString,
  })  : _preferences = preferences,
        _readString = readString,
        _writeString = writeString,
        _removeString = removeString;

  SharedPreferencesAsync? _preferences;
  final ReadString? _readString;
  final WriteString? _writeString;
  final RemoveString? _removeString;

  @override
  Future<String?> read(String key) {
    final readString = _readString;
    if (readString != null) {
      return readString(key);
    }

    return _resolvedPreferences.getString(key);
  }

  @override
  Future<void> write(String key, String value) {
    final writeString = _writeString;
    if (writeString != null) {
      return writeString(key, value);
    }

    return _resolvedPreferences.setString(key, value);
  }

  @override
  Future<void> delete(String key) {
    final removeString = _removeString;
    if (removeString != null) {
      return removeString(key);
    }

    return _resolvedPreferences.remove(key);
  }

  SharedPreferencesAsync get _resolvedPreferences {
    return _preferences ??= SharedPreferencesAsync();
  }
}
