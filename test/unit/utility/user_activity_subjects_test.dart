import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user_activity_record.dart';
import 'package:ctrim_app/utility/user_activity_messages.dart';
import 'package:ctrim_app/utility/user_activity_subjects.dart';

UserActivityRecord _record(
  String log, {
  String id = '1',
  String title = '',
  String parentId = '',
}) {
  return UserActivityRecord(
    log: log,
    ts: DateTime(2026, 10, 10, 8, 55),
    documentId: id,
    title: title,
    parentId: parentId,
  );
}

void main() {
  group('UserActivitySubjects.kindOf', () {
    test('maps stored messages to the record they touch', () {
      expect(UserActivitySubjects.kindOf(UserActivityMessages.editedBulletinPost),
          UserActivityKind.post);
      expect(
          UserActivitySubjects.kindOf(
              UserActivityMessages.editedVolunteerProfile),
          UserActivityKind.person);
      expect(UserActivitySubjects.kindOf(UserActivityMessages.editedChurchPage),
          UserActivityKind.churchPage);
      expect(UserActivitySubjects.kindOf(UserActivityMessages.editedUserTag),
          UserActivityKind.ministry);
      expect(UserActivitySubjects.kindOf('Something new'),
          UserActivityKind.other);
    });
  });

  group('UserActivitySubjects.resolve', () {
    test('live title wins over the stored one', () {
      final subject = UserActivitySubjects.resolve(
        _record(UserActivityMessages.editedBulletinPost,
            id: '738', title: 'Old title'),
        lookups: {UserActivityKind.post: (id) => 'Sunday Service'},
      );

      expect(subject.title, 'Sunday Service');
      expect(subject.canOpen, isTrue);
    });

    test('older rows without a stored title use the live lookup', () {
      final subject = UserActivitySubjects.resolve(
        _record(UserActivityMessages.editedVolunteerProfile, id: 'u1'),
        lookups: {UserActivityKind.person: (id) => 'Timothy Abatayo'},
      );

      expect(subject.title, 'Timothy Abatayo');
      expect(subject.canOpen, isTrue);
    });

    test('a record the lookup cannot find keeps its title but does not open',
        () {
      final subject = UserActivitySubjects.resolve(
        _record(UserActivityMessages.editedBulletinPost,
            id: '9', title: 'Removed post'),
        lookups: {UserActivityKind.post: (id) => null},
      );

      expect(subject.title, 'Removed post');
      expect(subject.canOpen, isFalse);
    });

    test('an unknown lookup result opens with the stored title', () {
      final subject = UserActivitySubjects.resolve(
        _record(UserActivityMessages.editedBulletinPost,
            id: '9', title: 'Stored'),
        lookups: {UserActivityKind.post: (id) => ''},
      );

      expect(subject.title, 'Stored');
      expect(subject.canOpen, isTrue);
    });

    test('deletions never open', () {
      final subject = UserActivitySubjects.resolve(
        _record(UserActivityMessages.deletedTestimonial, title: 'Jane'),
      );

      expect(subject.title, 'Jane');
      expect(subject.canOpen, isFalse);
    });

    test('church pages need their church to open', () {
      final withoutParent = UserActivitySubjects.resolve(
        _record(UserActivityMessages.editedChurchPage, id: 'p1'),
      );
      final withParent = UserActivitySubjects.resolve(
        _record(UserActivityMessages.editedChurchPage,
            id: 'p1', parentId: 'c1'),
      );

      expect(withoutParent.canOpen, isFalse);
      expect(withParent.canOpen, isTrue);
      expect(withParent.parentId, 'c1');
    });

    test('locations and templates have no destination', () {
      expect(
        UserActivitySubjects.resolve(
                _record(UserActivityMessages.editedLocation, title: 'Belfast'))
            .canOpen,
        isFalse,
      );
      expect(
        UserActivitySubjects.resolve(
                _record(UserActivityMessages.editedPostTemplate))
            .canOpen,
        isFalse,
      );
    });

    group('guests', () {
      test('do not see a stored full name', () {
        final subject = UserActivitySubjects.resolve(
          _record(UserActivityMessages.editedVolunteerProfile,
              id: 'u1', title: 'Timothy Abatayo'),
          lookups: {UserActivityKind.person: (id) => null},
          guest: true,
        );

        expect(subject.title, isEmpty);
        expect(subject.canOpen, isFalse);
      });

      test('see the guest-aware live name', () {
        final subject = UserActivitySubjects.resolve(
          _record(UserActivityMessages.editedVolunteerProfile,
              id: 'u1', title: 'Timothy Abatayo'),
          lookups: {UserActivityKind.person: (id) => 'Timothy A.'},
          guest: true,
        );

        expect(subject.title, 'Timothy A.');
        expect(subject.canOpen, isTrue);
      });

      test('keep stored post titles', () {
        final subject = UserActivitySubjects.resolve(
          _record(UserActivityMessages.editedBulletinPost,
              title: 'Sunday Service'),
          guest: true,
        );

        expect(subject.title, 'Sunday Service');
      });

      test('cannot open post tags', () {
        final subject = UserActivitySubjects.resolve(
          _record(UserActivityMessages.editedPostTag),
          lookups: {UserActivityKind.postTag: (id) => 'Youth'},
          guest: true,
        );

        expect(subject.canOpen, isFalse);
      });
    });
  });

  test('postIds collects post rows only', () {
    final ids = UserActivitySubjects.postIds([
      _record(UserActivityMessages.editedBulletinPost, id: '738'),
      _record(UserActivityMessages.createdBulletinPost, id: '741'),
      _record(UserActivityMessages.editedVolunteerProfile, id: 'u1'),
      _record(UserActivityMessages.editedBulletinPost, id: '738'),
    ]);

    expect(ids, {'738', '741'});
  });
}
