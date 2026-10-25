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

    test('bySurname clusters a shared surname and leaves singles loose', () {
      final users = [
        u(id: 'amy', forname: 'Amy', surname: 'Adams'),
        u(id: 'ben', forname: 'Ben', surname: 'Campbell'),
        u(id: 'cara', forname: 'Cara', surname: 'campbell'),
        u(id: 'dan', forname: 'Dan', surname: 'Young'),
      ];

      final blocks = PeopleDirectorySections.bySurname(users);

      expect(blocks, hasLength(3));
      expect(blocks[0].canSelectTogether, isFalse);
      expect(blocks[0].users.map((e) => e.id), ['amy']);
      expect(blocks[1].canSelectTogether, isTrue);
      expect(blocks[1].surnameLabel, 'Campbell');
      expect(blocks[1].users.map((e) => e.id), ['ben', 'cara']);
      expect(blocks[2].canSelectTogether, isFalse);
      expect(blocks[2].users.map((e) => e.id), ['dan']);
    });

    test('bySurname does not treat a blank or unique surname as a family', () {
      final users = [
        u(id: 'a', forname: 'Ann', surname: ''),
        u(id: 'b', forname: 'Bob', surname: ' '),
        u(id: 'c', forname: 'Cara', surname: 'Campbell'),
        u(id: 'd', forname: 'Dee', surname: 'Campbell-Smith'),
      ];

      final blocks = PeopleDirectorySections.bySurname(users);

      expect(blocks, hasLength(1));
      expect(blocks.single.canSelectTogether, isFalse);
      expect(blocks.single.users.map((e) => e.id), ['a', 'b', 'c', 'd']);
    });

    test('bySurname keeps people between two families in order', () {
      final users = [
        u(id: 'a1', surname: 'Adams'),
        u(id: 'a2', surname: 'Adams'),
        u(id: 'b', surname: 'Baker'),
        u(id: 'c1', surname: 'Cole'),
        u(id: 'c2', surname: 'Cole'),
      ];

      final blocks = PeopleDirectorySections.bySurname(users);

      expect(blocks.map((block) => block.surnameLabel), [ 'Adams', null, 'Cole']);
      expect(blocks[1].users.map((e) => e.id), ['b']);
    });
  });
}
