import 'package:bare_brain_app/src/features/chat/data/datasources/shared_preferences_key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SharedPreferencesKeyValueStore', () {
    test('delegates string reads, writes, and deletes', () async {
      final values = <String, String>{};
      final store = SharedPreferencesKeyValueStore(
        readString: (key) async => values[key],
        writeString: (key, value) async {
          values[key] = value;
        },
        removeString: (key) async {
          values.remove(key);
        },
      );

      await store.write('session', 'payload');
      expect(await store.read('session'), 'payload');

      await store.delete('session');
      expect(await store.read('session'), isNull);
    });
  });
}
