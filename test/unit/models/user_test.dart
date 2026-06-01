import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user.dart';

void main() {
  group('User', () {
    group('constructor', () {
      test('creates user with required parameters', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');

        expect(user.id, '1');
        expect(user.forname, 'John');
        expect(user.surname, 'Smith');
        expect(user.imgSrc, '');
        expect(user.location, 'Belfast');
        expect(user.isAreaAdmin, false);
        expect(user.isLeader, false);
        expect(user.authID, '');
      });

      test('creates user with all parameters', () {
        final user = User(
          id: '42',
          forname: 'Jane',
          surname: 'Doe',
          imgSrc: 'https://example.com/img.png',
          location: 'Dublin',
          isAreaAdmin: true,
          isLeader: true,
          authID: 'auth-abc',
        );

        expect(user.id, '42');
        expect(user.forname, 'Jane');
        expect(user.surname, 'Doe');
        expect(user.imgSrc, 'https://example.com/img.png');
        expect(user.location, 'Dublin');
        expect(user.isAreaAdmin, true);
        expect(user.isLeader, true);
        expect(user.authID, 'auth-abc');
      });
    });

    group('fromMap', () {
      test('creates user from a Firestore-style map', () {
        final map = {
          'Forename': 'Alice',
          'Surname': 'Brown',
          'Location': 'Cork',
          'IsAreaAdmin': false,
          'IsLeader': true,
          'AuthID': 'auth-xyz',
          'ImgSrc': 'https://example.com/alice.png',
        };

        final user = User.fromMap('99', map);

        expect(user.id, '99');
        expect(user.forname, 'Alice');
        expect(user.surname, 'Brown');
        expect(user.location, 'Cork');
        expect(user.isAreaAdmin, false);
        expect(user.isLeader, true);
        expect(user.authID, 'auth-xyz');
        expect(user.imgSrc, 'https://example.com/alice.png');
      });
    });

    group('toJson', () {
      test('serialises user to a map with correct keys', () {
        final user = User(
          id: '1',
          forname: 'John',
          surname: 'Smith',
          imgSrc: 'img.png',
          location: 'Belfast',
          isAreaAdmin: false,
          isLeader: true,
          authID: 'auth-1',
        );

        final json = user.toJson() as Map<String, dynamic>;

        expect(json['Forename'], 'John');
        expect(json['Surname'], 'Smith');
        expect(json['Location'], 'Belfast');
        expect(json['IsAreaAdmin'], false);
        expect(json['IsLeader'], true);
        expect(json['ImgSrc'], 'img.png');
        expect(json['AuthID'], 'auth-1');
      });
    });

    group('computed name getters', () {
      test('fullname combines forename and surname', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        expect(user.fullname, 'John Smith');
      });

      test('initials uses first letter of forename and each surname part', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        expect(user.initials, 'JS');
      });

      test('initials handles hyphenated surname', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith-Jones');
        expect(user.initials, 'JSJ');
      });

      test('shortenedFullName abbreviates each surname part', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        expect(user.shortenedFullName, 'John S.');
      });

      test('shortenedFullName handles hyphenated surname', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith-Jones');
        expect(user.shortenedFullName, 'John SJ.');
      });
    });

    group('roles and posts', () {
      test('roles returns null when not set', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        expect(user.roles, isNull);
      });

      test('posts returns null when not set', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        expect(user.posts, isNull);
      });

      test('setRoles stores and returns an unmodifiable list', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        final roles = [
          {'postID': 'p1', 'title': 'Leader'},
        ];
        user.setRoles(roles);

        expect(user.roles, isNotNull);
        expect(user.roles!.length, 1);
        expect(() => user.roles!.add({}), throwsUnsupportedError);
      });

      test('setPosts stores and returns an unmodifiable list', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        user.setPosts([
          {'id': 'post-1'},
        ]);

        expect(user.posts, isNotNull);
        expect(user.posts!.length, 1);
        expect(() => user.posts!.add({}), throwsUnsupportedError);
      });

      test('removeRoles removes matching entries', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        user.setRoles([
          {'postID': 'p1'},
          {'postID': 'p2'},
        ]);
        user.removeRoles(['p1']);

        expect(user.roles!.length, 1);
        expect(user.roles!.first['postID'], 'p2');
      });

      test('removeAllPosts removes matching entries', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        user.setPosts([
          {'id': 'post-1'},
          {'id': 'post-2'},
        ]);
        user.removeAllPosts(['post-1']);

        expect(user.posts!.length, 1);
        expect(user.posts!.first['id'], 'post-2');
      });
    });

    group('setImgSrc', () {
      test('updates imgSrc', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        user.setImgSrc('new_image.png');
        expect(user.imgSrc, 'new_image.png');
      });
    });
  });
}
