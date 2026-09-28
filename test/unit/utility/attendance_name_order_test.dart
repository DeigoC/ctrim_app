import 'package:ctrim_app/models/event/event_attendance.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/attendance_name_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final adam = User(id: 'adam', forname: 'Zoe', surname: 'Adams');
  final brian = User(id: 'brian', forname: 'Adam', surname: 'Brown');
  final cara = User(id: 'cara', forname: 'Cara', surname: 'Brown');
  final users = {adam.id: adam, brian.id: brian, cara.id: cara};

  User? lookup(String id) => users[id];

  group('AttendanceNameOrder', () {
    test('userIdsBySurname orders by surname then forename', () {
      final ordered = AttendanceNameOrder.userIdsBySurname(
        ['brian', 'cara', 'adam'],
        lookup,
      );

      expect(ordered, ['adam', 'brian', 'cara']);
    });

    test('userIdsBySurname is case-insensitive and keeps unknown ids', () {
      final mixed = User(id: 'mixed', forname: 'Ann', surname: 'adams');
      final ordered = AttendanceNameOrder.userIdsBySurname(
        ['missing', 'brian', 'mixed'],
        (id) => id == 'mixed' ? mixed : users[id],
      );

      expect(ordered.first, 'mixed');
      expect(ordered[1], 'brian');
      expect(ordered.last, 'missing');
    });

    test('attendeesBySurname uses the profile surname, not the forename', () {
      final attendees = [
        AttendeeEntry.user(
          userId: 'brian',
          displayName: 'Adam Brown',
          addedBy: 'leader',
        ),
        AttendeeEntry.user(
          userId: 'adam',
          displayName: 'Zoe Adams',
          addedBy: 'leader',
        ),
        AttendeeEntry.external(
          name: 'Maria Guest',
          addedBy: 'leader',
          id: 'ext-guest',
        ),
      ];

      final ordered =
          AttendanceNameOrder.attendeesBySurname(attendees, lookup);

      expect(ordered.map((entry) => entry.displayName), [
        'Zoe Adams',
        'Adam Brown',
        'Maria Guest',
      ]);
    });
  });
}
