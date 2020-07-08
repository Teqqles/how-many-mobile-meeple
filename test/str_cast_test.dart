
import 'package:how_many_mobile_meeple/str_cast.dart';
import 'package:test/test.dart';

main() {
  group('castToList', () {
    test('converts a string representation of list to a list', () {
      var expected = ["123"];
      var actual = StrCast("[123]").castToList();
      expect(actual, expected);
    });
    test('converts multiple entries from a stringified list', () {
      var expected = ["test 1", "test 2"];
      var actual = StrCast(expected.toString()).castToList();
      expect(actual, expected);
    });
  });
}
