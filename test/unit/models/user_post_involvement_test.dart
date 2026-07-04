import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user_post_involvement.dart';

void main() {
  group('UserPostInvolvement', () {
    group('constructor', () {
      test('creates with required parameters', () {
        final involvement = UserPostInvolvement(
          postID: 'post-1',
          ownership: PostOwnership.author,
        );

        expect(involvement.postID, 'post-1');
        expect(involvement.ownership, PostOwnership.author);
      });
    });

    group('fromMap', () {
      test('creates from a Firestore-style map', () {
        final involvement = UserPostInvolvement.fromMap({
          'id': 'post-1',
          'ownership': 'contributor',
        });

        expect(involvement.postID, 'post-1');
        expect(involvement.ownership, PostOwnership.contributor);
      });
    });

    group('toJson', () {
      test('serialises to Firestore-compatible keys', () {
        final involvement = UserPostInvolvement(
          postID: 'post-1',
          ownership: PostOwnership.contributor,
        );

        final json = involvement.toJson();

        expect(json['id'], 'post-1');
        expect(json['ownership'], 'contributor');
      });
    });

    group('PostOwnership', () {
      test('fromString parses known values', () {
        expect(PostOwnership.fromString('author'), PostOwnership.author);
        expect(PostOwnership.fromString('contributor'), PostOwnership.contributor);
      });

      test('fromString throws for unknown values', () {
        expect(() => PostOwnership.fromString('editor'), throwsArgumentError);
      });
    });

    group('list helpers', () {
      test('listFromFirestore and listToFirestore round-trip', () {
        final raw = [
          {'id': 'post-1', 'ownership': 'author'},
          {'id': 'post-2', 'ownership': 'contributor'},
        ];

        final involvements = UserPostInvolvement.listFromFirestore(raw);
        final restored = UserPostInvolvement.listToFirestore(involvements);

        expect(involvements.length, 2);
        expect(restored, raw);
      });
    });
  });
}
