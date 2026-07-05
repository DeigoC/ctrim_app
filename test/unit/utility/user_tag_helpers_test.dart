import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_tag.dart';
import 'package:ctrim_app/utility/user_tag_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserTagHelpers sorting', () {
    final worship = UserTag(id: 'worship', name: 'Worship', displayOrder: 1);
    final tech = UserTag(id: 'tech', name: 'Technical', displayOrder: 2);
    final allTags = [worship, tech];

    test('compareUsersBySurname sorts surname then forename', () {
      final users = [
        User(id: '1', forname: 'Bob', surname: 'Smith'),
        User(id: '2', forname: 'Alice', surname: 'Adams'),
        User(id: '3', forname: 'Zara', surname: 'Smith'),
      ]..sort(UserTagHelpers.compareUsersBySurname);

      expect(users.map((u) => u.id).toList(), ['2', '1', '3']);
    });

    test('compareUsersByPrimaryTag groups by tag order then surname', () {
      final users = [
        User(id: '1', forname: 'Bob', surname: 'Zulu', tagIDs: ['tech']),
        User(id: '2', forname: 'Amy', surname: 'Adams', tagIDs: ['worship']),
        User(id: '3', forname: 'Cal', surname: 'Brown'),
        User(id: '4', forname: 'Dan', surname: 'Adams', tagIDs: ['worship']),
      ]..sort((a, b) => UserTagHelpers.compareUsersByPrimaryTag(a, b, allTags));

      expect(users.map((u) => u.id).toList(), ['2', '4', '1', '3']);
    });
  });
}
