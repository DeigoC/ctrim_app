import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_post_involvement.dart';
import 'package:ctrim_app/models/user_role_assignment.dart';

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
        expect(user.canManageInfo, false);
        expect(user.canManageVolunteers, false);
        expect(user.canManagePostTemplates, false);
        expect(user.canManageCellGroups, false);
        expect(user.authID, '');
        expect(user.isPlaceholder, false);
        expect(user.createdByUserID, '');
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
          createdByUserID: '7',
          isPlaceholder: true,
        );

        expect(user.id, '42');
        expect(user.forname, 'Jane');
        expect(user.surname, 'Doe');
        expect(user.imgSrc, 'https://example.com/img.png');
        expect(user.location, 'Dublin');
        expect(user.isAreaAdmin, true);
        expect(user.isLeader, true);
        expect(user.canManageInfo, true);
        expect(user.canManageVolunteers, true);
        expect(user.canManagePostTemplates, true);
        expect(user.canManageCellGroups, true);
        expect(user.authID, 'auth-abc');
        expect(user.tagIDs, isEmpty);
        expect(user.createdByUserID, '7');
        expect(user.isPlaceholder, true);
      });
    });

    group('canManageInfo', () {
      test('is true for area admin only', () {
        final user = User(
          id: '1',
          forname: 'A',
          surname: 'B',
          isAreaAdmin: true,
        );
        expect(user.canManageInfo, true);
        expect(user.canManageVolunteers, true);
        expect(user.canManagePostTemplates, false);
        expect(user.canManageCellGroups, true);
      });

      test('is true for leader only', () {
        final user = User(
          id: '1',
          forname: 'A',
          surname: 'B',
          isLeader: true,
        );
        expect(user.canManageInfo, true);
        expect(user.canManageVolunteers, false);
        expect(user.canManagePostTemplates, true);
        expect(user.canManageCellGroups, false);
      });

      test('is false for regular users', () {
        final user = User(id: '1', forname: 'A', surname: 'B');
        expect(user.canManageInfo, false);
        expect(user.canManageVolunteers, false);
        expect(user.canManagePostTemplates, false);
        expect(user.canManageCellGroups, false);
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
          'Tags': ['tag-1', 'tag-2'],
          'CreatedByUserID': '3',
          'IsPlaceholder': true,
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
        expect(user.tagIDs, ['tag-1', 'tag-2']);
        expect(user.createdByUserID, '3');
        // Linked Auth clears a stale IsPlaceholder flag.
        expect(user.isPlaceholder, false);
      });

      test('fromMap keeps IsPlaceholder when AuthID is empty', () {
        final user = User.fromMap('99', {
          'Forename': 'Temp',
          'Surname': 'Person',
          'Location': 'Belfast',
          'IsAreaAdmin': false,
          'IsLeader': false,
          'AuthID': '',
          'ImgSrc': '',
          'CreatedByUserID': '3',
          'IsPlaceholder': true,
        });
        expect(user.isPlaceholder, true);
        expect(user.createdByUserID, '3');
      });

      test('fromMap defaults Tags to empty list when missing', () {
        final user = User.fromMap('1', {
          'Forename': 'A',
          'Surname': 'B',
          'Location': 'Belfast',
          'IsAreaAdmin': false,
          'IsLeader': false,
          'AuthID': '',
          'ImgSrc': '',
        });
        expect(user.tagIDs, isEmpty);
        expect(user.isPlaceholder, false);
        expect(user.createdByUserID, '');
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
          createdByUserID: '9',
          isPlaceholder: true,
        );

        final json = user.toJson() as Map<String, dynamic>;

        expect(json['Forename'], 'John');
        expect(json['Surname'], 'Smith');
        expect(json['Location'], 'Belfast');
        expect(json['IsAreaAdmin'], false);
        expect(json['IsLeader'], true);
        expect(json['ImgSrc'], 'img.png');
        expect(json['AuthID'], 'auth-1');
        expect(json['Tags'], isEmpty);
        expect(json['CreatedByUserID'], '9');
        expect(json['IsPlaceholder'], true);
      });

      test('serialises tag IDs', () {
        final user = User(
          id: '1',
          forname: 'John',
          surname: 'Smith',
          tagIDs: ['a', 'b'],
        );
        final json = user.toJson() as Map<String, dynamic>;
        expect(json['Tags'], ['a', 'b']);
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
        user.setRoles([
          UserRoleAssignment(
            postID: 'p1',
            roleID: 1,
            start: DateTime(2024, 6, 15, 10),
            end: DateTime(2024, 6, 15, 11),
            title: 'Leader',
          ),
        ]);

        expect(user.roles, isNotNull);
        expect(user.roles!.length, 1);
        expect(user.roles!.first.title, 'Leader');
        expect(() => user.roles!.add(user.roles!.first), throwsUnsupportedError);
      });

      test('setPosts stores and returns an unmodifiable list', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        user.setPosts([
          UserPostInvolvement(postID: 'post-1', ownership: PostOwnership.author),
        ]);

        expect(user.posts, isNotNull);
        expect(user.posts!.length, 1);
        expect(user.posts!.first.postID, 'post-1');
        expect(() => user.posts!.add(user.posts!.first), throwsUnsupportedError);
      });

      test('removeRoles removes matching entries', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        user.setRoles([
          UserRoleAssignment(
            postID: 'p1',
            roleID: 1,
            start: DateTime(2024, 6, 15, 10),
            end: DateTime(2024, 6, 15, 11),
            title: 'A',
          ),
          UserRoleAssignment(
            postID: 'p2',
            roleID: 2,
            start: DateTime(2024, 6, 16, 10),
            end: DateTime(2024, 6, 16, 11),
            title: 'B',
          ),
        ]);
        user.removeRoles(['p1']);

        expect(user.roles!.length, 1);
        expect(user.roles!.first.postID, 'p2');
      });

      test('removeAllPosts removes matching entries', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        user.setPosts([
          UserPostInvolvement(postID: 'post-1', ownership: PostOwnership.author),
          UserPostInvolvement(postID: 'post-2', ownership: PostOwnership.contributor),
        ]);
        user.removeAllPosts(['post-1']);

        expect(user.posts!.length, 1);
        expect(user.posts!.first.postID, 'post-2');
      });
    });

    group('tag IDs', () {
      test('setTagIDs stores unmodifiable list', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith');
        user.setTagIDs(['t1', 't2']);

        expect(user.tagIDs, ['t1', 't2']);
        expect(() => user.tagIDs.add('t3'), throwsUnsupportedError);
      });

      test('hasTag and hasAnyTag work', () {
        final user = User(id: '1', forname: 'John', surname: 'Smith', tagIDs: ['worship', 'tech']);
        expect(user.hasTag('worship'), isTrue);
        expect(user.hasTag('usher'), isFalse);
        expect(user.hasAnyTag(['usher', 'tech']), isTrue);
        expect(user.hasAnyTag(['usher']), isFalse);
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
