import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage_manager/storage_manager.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('DataPersistor', () {
    test('saves and reads a string', () async {
      await DataPersistor().saveString('notes/a.txt', 'hola');
      expect(await DataPersistor().getString('notes/a.txt'), 'hola');
    });

    test('saves and reads bytes', () async {
      final bytes = Uint8List.fromList([0, 1, 2, 255]);
      await DataPersistor().saveImage('img/a.png', bytes);
      expect(await DataPersistor().getBytes('img/a.png'), bytes);
    });

    test('saves and reads a JSON object', () async {
      final json = {'name': 'Facturanza', 'count': 3};
      expect(await DataPersistor().saveObject('data/a.json', json), isTrue);
      expect(await DataPersistor().getObject('data/a.json'), json);
    });

    test('returns empty values for missing keys', () async {
      expect(await DataPersistor().getString('missing'), '');
      expect(await DataPersistor().getBytes('missing'), isEmpty);
      expect(await DataPersistor().getObject('missing'), isEmpty);
    });

    test('removes a value', () async {
      await DataPersistor().saveString('tmp', 'x');
      await DataPersistor().removeObject('tmp');
      expect(await DataPersistor().getString('tmp'), '');
    });
  });

  group('StorageProvider local storage', () {
    test('save routes each value type and get returns it', () async {
      await StorageProvider.save('s', 'text', toLocalStorage: true);
      await StorageProvider.save('b', Uint8List.fromList([7, 8]), toLocalStorage: true);
      await StorageProvider.save('l', <int>[9, 10], toLocalStorage: true);
      await StorageProvider.save('j', {'k': 'v'}, toLocalStorage: true);

      expect(await StorageProvider.get('s', isLocal: true), 'text');
      expect(await StorageProvider.get('b', isLocal: true, type: StorageType.image), [7, 8]);
      expect(await StorageProvider.get('l', isLocal: true, type: StorageType.video), [9, 10]);
      expect(await StorageProvider.get('j', isLocal: true, type: StorageType.json), {'k': 'v'});
    });

    test('remove deletes a local value', () async {
      await StorageProvider.saveLocalString('r', 'x');
      await StorageProvider.remove('r', isLocal: true);
      expect(await StorageProvider.getLocalString('r'), '');
    });
  });
}
