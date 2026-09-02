import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/people_directory_sections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  User u({required String id, String forname = 'A', String surname = 'B'}) =>
      User(id: id, forname: forname, surname: surname);

  group('PeopleDirectorySections', () {
    test('letterForUser prefers surname initial', () {
      expect(PeopleDirectorySections.letterForUser(u(id: '1', forname: 'Z', surname: 'Abatayo')), 'A');
    });

    test('letterForUser falls back to forename', () {
      expect(PeopleDirectorySections.letterForUser(u(id: '1', forname: 'Mia', surname: '')), 'M');
    });

    test('letterForUser uses hash for empty or non-alpha', () {
      expect(PeopleDirectorySections.letterForUser(u(id: '1', forname: '', surname: '')), '#');
      expect(PeopleDirectorySections.letterForUser(u(id: '2', forname: '1st', surname: '')), '#');
    });

    test('bySurnameLetter groups consecutive letters', () {
      final users = [
        u(id: 'a', surname: 'Abatayo'),
        u(id: 'b', surname: 'Bihag'),
        u(id: 'c', surname: 'Collado'),
        u(id: 'd', surname: 'Dy'),
      ];

      final sections = PeopleDirectorySections.bySurnameLetter(users);

      expect(sections, hasLength(4));
      expect(sections[0].letter, 'A');
      expect(sections[0].users.map((e) => e.id), ['a']);
      expect(sections[1].letter, 'B');
      expect(sections[1].users.map((e) => e.id), ['b']);
      expect(sections[2].letter, 'C');
      expect(sections[2].users.map((e) => e.id), ['c']);
      expect(sections[3].letter, 'D');
      expect(sections[3].users.map((e) => e.id), ['d']);
    });
  });
}
