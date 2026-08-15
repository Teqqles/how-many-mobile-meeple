@Tags(['unit'])
library;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/util/retry_scheduler.dart';

void main() {
  group('RetryScheduler', () {
    test('runs the action after the delay', () {
      fakeAsync((async) {
        final s = RetryScheduler();
        var ran = 0;
        s.schedule(const Duration(seconds: 5), () => ran++);
        expect(ran, 0);
        async.elapse(const Duration(seconds: 5));
        expect(ran, 1);
      });
    });

    test('scheduling again cancels the prior pending action', () {
      fakeAsync((async) {
        final s = RetryScheduler();
        var first = 0;
        var second = 0;
        s.schedule(const Duration(seconds: 5), () => first++);
        s.schedule(const Duration(seconds: 5), () => second++);
        async.elapse(const Duration(seconds: 5));
        expect(first, 0);
        expect(second, 1);
      });
    });

    test('cancel prevents a pending action from running', () {
      fakeAsync((async) {
        final s = RetryScheduler();
        var ran = 0;
        s.schedule(const Duration(seconds: 5), () => ran++);
        s.cancel();
        async.elapse(const Duration(seconds: 5));
        expect(ran, 0);
      });
    });

    test('isActive reflects a pending action', () {
      fakeAsync((async) {
        final s = RetryScheduler();
        expect(s.isActive, isFalse);
        s.schedule(const Duration(seconds: 5), () {});
        expect(s.isActive, isTrue);
        async.elapse(const Duration(seconds: 5));
        expect(s.isActive, isFalse);
      });
    });
  });
}
