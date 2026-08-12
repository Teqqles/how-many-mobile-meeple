@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppModel.storeDebounceDelay = const Duration(milliseconds: 30);
  });

  tearDown(() {
    AppModel.storeDebounceDelay = const Duration(milliseconds: 300);
  });

  group('AppModel.updateStoreDebounced', () {
    test('collapses rapid calls into a single persistence write', () async {
      final model = AppModel()..hasLoadedPersistedData = true;
      model.items.itemList.add(Item('teqqles'));

      // Simulate a slider being dragged across five divisions.
      for (var i = 0; i < 5; i++) {
        model.updateStoreDebounced();
      }

      expect(model.storeWriteCount, 0,
          reason: 'nothing should persist until the debounce settles');

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(model.storeWriteCount, 1,
          reason: 'five rapid calls must persist exactly once after settling');
    });

    test('notifies listeners immediately on every call for a responsive UI',
        () async {
      final model = AppModel()..hasLoadedPersistedData = true;
      var notifications = 0;
      model.addListener(() => notifications++);

      model.updateStoreDebounced();
      model.updateStoreDebounced();
      model.updateStoreDebounced();

      // No delay: the notifications must have already fired synchronously,
      // well before the debounced write lands.
      expect(notifications, 3);
      expect(model.storeWriteCount, 0);
    });

    test('flushes a pending write on dispose so no changes are lost', () async {
      final model = AppModel()..hasLoadedPersistedData = true;
      model.items.itemList.add(Item('teqqles'));

      model.updateStoreDebounced();
      expect(model.storeWriteCount, 0);

      // User navigates away before the debounce fires.
      model.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(model.storeWriteCount, 1,
          reason: 'the pending write must flush when the model is disposed');
    });

    test('does not write again on dispose when nothing is pending', () async {
      final model = AppModel()..hasLoadedPersistedData = true;
      model.updateStoreDebounced();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(model.storeWriteCount, 1);

      model.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(model.storeWriteCount, 1,
          reason: 'dispose must not trigger a redundant write');
    });
  });

  group('AppModel.updateStore', () {
    test('persists synchronously without debouncing', () async {
      final model = AppModel()..hasLoadedPersistedData = true;
      model.items.itemList.add(Item('teqqles'));

      await model.updateStore();

      expect(model.storeWriteCount, 1,
          reason: 'the write completes before updateStore returns');
    });

    test('cancels a pending debounced write so it is not written twice',
        () async {
      final model = AppModel()..hasLoadedPersistedData = true;

      model.updateStoreDebounced();
      await model.updateStore();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(model.storeWriteCount, 1,
          reason: 'the immediate write subsumes the pending debounced one');
    });
  });
}
