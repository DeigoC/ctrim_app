import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/donation_details.dart';

void main() {
  group('DonationDetails', () {
    DonationDetails sample() {
      return DonationDetails(
        id: 'general',
        accountName: ' CTRIM ',
        sortCode: '123456',
        accountNumber: '12 34 56 78',
        reference: ' Your name ',
        notes: const ['Please use your name.', '  ', 'Ask a leader.'],
      );
    }

    group('constructor', () {
      test('stores the published fields', () {
        final details = sample();

        expect(details.id, 'general');
        expect(details.accountName, ' CTRIM ');
        expect(details.sortCode, '123456');
        expect(details.accountNumber, '12 34 56 78');
        expect(details.reference, ' Your name ');
        expect(details.notes, ['Please use your name.', '  ', 'Ask a leader.']);
      });

      test('notes cannot be mutated from outside', () {
        final details = sample();

        expect(
          () => details.notes.add('extra'),
          throwsUnsupportedError,
        );
      });
    });

    group('bankLines', () {
      test('formats the sort code and drops blank lines', () {
        final details = DonationDetails(
          id: 'general',
          accountName: 'CTRIM',
          sortCode: '12-34-56',
          accountNumber: '12345678',
          reference: '   ',
        );

        expect(details.hasBankDetails, isTrue);
        expect(
          details.bankLines.map((line) => (line.field, line.value)),
          [
            (DonationBankField.accountName, 'CTRIM'),
            (DonationBankField.sortCode, '12-34-56'),
            (DonationBankField.accountNumber, '12345678'),
          ],
        );
      });

      test('omits every bank row when the account is still empty', () {
        expect(DonationDetails.published.hasBankDetails, isFalse);
        expect(DonationDetails.published.bankLines, isEmpty);
        expect(DonationDetails.published.notes, isNotEmpty);
      });
    });

    group('formatSortCode', () {
      test('groups six digits', () {
        expect(DonationDetails.formatSortCode('123456'), '12-34-56');
        expect(DonationDetails.formatSortCode('12 34 56'), '12-34-56');
      });

      test('leaves an incomplete code unchanged', () {
        expect(DonationDetails.formatSortCode('12-34'), '12-34');
        expect(DonationDetails.formatSortCode(''), '');
      });
    });

    group('clipboardBlock', () {
      test('joins the visible lines', () {
        final text = sample().clipboardBlock((field) {
          switch (field) {
            case DonationBankField.accountName:
              return 'Account name';
            case DonationBankField.sortCode:
              return 'Sort code';
            case DonationBankField.accountNumber:
              return 'Account number';
            case DonationBankField.reference:
              return 'Payment reference';
          }
        });

        expect(
          text,
          'Account name: CTRIM\n'
          'Sort code: 12-34-56\n'
          'Account number: 12345678\n'
          'Payment reference: Your name',
        );
      });
    });

    group('fromMap / toJson', () {
      test('round-trips the account and skips blank notes', () {
        final details = DonationDetails.fromMap('building', {
          'AccountName': 'CTRIM Building',
          'SortCode': '998877',
          'AccountNumber': '87654321',
          'Reference': 'Building',
          'Notes': ['First', '', 2, 'Second'],
        });

        expect(details.id, 'building');
        expect(details.notes, ['First', '2', 'Second']);
        expect(details.toJson(), {
          'AccountName': 'CTRIM Building',
          'SortCode': '998877',
          'AccountNumber': '87654321',
          'Reference': 'Building',
          'Notes': ['First', '2', 'Second'],
        });
      });

      test('treats a missing map as empty details', () {
        final details = DonationDetails.fromMap('general', {});

        expect(details.accountName, '');
        expect(details.bankLines, isEmpty);
        expect(details.notes, isEmpty);
        expect(details.clipboardBlock((_) => 'Label'), '');
      });
    });
  });
}
