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
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _readString = readString,
        _writeString = writeString,
        _removeString = removeString;

  final SharedPreferencesAsync _preferences;
  final ReadString? _readString;
  final WriteString? _writeString;
  final RemoveString? _removeString;

  @override
  Future<String?> read(String key) {
    final readString = _readString;
    if (readString != null) {
      return readString(key);
    }

    return _preferences.getString(key);
  }

  @override
  Future<void> write(String key, String value) {
    final writeString = _writeString;
    if (writeString != null) {
      return writeString(key, value);
    }

    return _preferences.setString(key, value);
  }

  @override
  Future<void> delete(String key) {
    final removeString = _removeString;
    if (removeString != null) {
      return removeString(key);
    }

    return _preferences.remove(key);
  }
}
