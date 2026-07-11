import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user_role_assignment.dart';

void main() {
  group('UserRoleAssignment', () {
    final start = DateTime(2024, 6, 15, 10, 0);
    final end = DateTime(2024, 6, 15, 11, 0);

    group('constructor', () {
      test('creates with required parameters', () {
        final assignment = UserRoleAssignment(
          postID: 'post-1',
          roleID: 1000,
          start: start,
          end: end,
          title: 'Setup',
        );

        expect(assignment.postID, 'post-1');
        expect(assignment.roleID, 1000);
        expect(assignment.start, start);
        expect(assignment.end, end);
        expect(assignment.title, 'Setup');
      });
    });

    group('fromMap', () {
      test('creates from a Firestore-style map', () {
        final assignment = UserRoleAssignment.fromMap({
          'postID': 'post-1',
          'id': 1000,
          'startMil': start.millisecondsSinceEpoch,
          'endMil': end.millisecondsSinceEpoch,
          'title': 'Setup',
        });

        expect(assignment.postID, 'post-1');
        expect(assignment.roleID, 1000);
        expect(assignment.start, start);
        expect(assignment.end, end);
        expect(assignment.title, 'Setup');
      });
    });

    group('toJson', () {
      test('serialises to Firestore-compatible keys', () {
        final assignment = UserRoleAssignment(
          postID: 'post-1',
          roleID: 1000,
          start: start,
          end: end,
          title: 'Setup',
        );

        final json = assignment.toJson();

        expect(json['postID'], 'post-1');
        expect(json['id'], 1000);
        expect(json['startMil'], start.millisecondsSinceEpoch);
        expect(json['endMil'], end.millisecondsSinceEpoch);
        expect(json['title'], 'Setup');
      });
    });

    group('list helpers', () {
      test('listFromFirestore and listToFirestore round-trip', () {
        final raw = [
          {
            'postID': 'post-1',
            'id': 1000,
            'startMil': start.millisecondsSinceEpoch,
            'endMil': end.millisecondsSinceEpoch,
            'title': 'Setup',
          },
        ];

        final assignments = UserRoleAssignment.listFromFirestore(raw);
        final restored = UserRoleAssignment.listToFirestore(assignments);

        expect(assignments.length, 1);
        expect(restored, raw);
      });
    });
  });
}
