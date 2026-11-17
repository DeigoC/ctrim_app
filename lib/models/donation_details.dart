import 'dart:collection';

/// One bank-transfer field shown on the Donations page.
enum DonationBankField {
  accountName,
  sortCode,
  accountNumber,
  reference,
}

/// A filled bank-transfer line, in display order.
class DonationBankLine {
  const DonationBankLine(this.field, this.value);

  final DonationBankField field;
  final String value;
}

/// Bank-transfer details and notes for the Donations page.
///
/// This is in-app content, not a Firestore collection. Edit [published] when
/// the account or the notes change. Empty bank fields are omitted from the page.
class DonationDetails {
  const DonationDetails({
    required String id,
    required String accountName,
    required String sortCode,
    required String accountNumber,
    String reference = '',
    List<String> notes = const [],
  })  : _id = id,
        _accountName = accountName,
        _sortCode = sortCode,
        _accountNumber = accountNumber,
        _reference = reference,
        _notes = notes;

  /// Giving details shown on the Donations page.
  ///
  /// Fill the account name, sort code, and account number here. A six-digit
  /// sort code is shown as `00-00-00`. Add further paragraphs to [notes].
  static const DonationDetails published = DonationDetails(
    id: 'general',
    accountName: '',
    sortCode: '402055',
    accountNumber: '70017647',
    reference: '',
    notes: [
      'Please use your name as the payment reference.',
      'If you have a question about a gift, speak to a church leader.',
    ],
  );

  final String _id;
  final String _accountName;
  final String _sortCode;
  final String _accountNumber;
  final String _reference;
  final List<String> _notes;

  String get id => _id;

  String get accountName => _accountName;

  String get sortCode => _sortCode;

  String get accountNumber => _accountNumber;

  /// What the donor should write as the payment reference. Empty hides the row.
  String get reference => _reference;

  List<String> get notes => UnmodifiableListView(_notes);

  /// Non-empty bank lines, in the order they appear on the page.
  List<DonationBankLine> get bankLines {
    final lines = <DonationBankLine>[];
    final name = _accountName.trim();
    if (name.isNotEmpty) {
      lines.add(DonationBankLine(DonationBankField.accountName, name));
    }
    final code = formatSortCode(_sortCode);
    if (code.isNotEmpty) {
      lines.add(DonationBankLine(DonationBankField.sortCode, code));
    }
    final number = _accountNumber.replaceAll(RegExp(r'\s'), '');
    if (number.isNotEmpty) {
      lines.add(DonationBankLine(DonationBankField.accountNumber, number));
    }
    final referenceText = _reference.trim();
    if (referenceText.isNotEmpty) {
      lines.add(DonationBankLine(DonationBankField.reference, referenceText));
    }
    return lines;
  }

  bool get hasBankDetails =>
      bankLines.any((line) => line.field != DonationBankField.reference);

  /// `Label: value` lines for the clipboard. [labelFor] supplies the visible name.
  String clipboardBlock(String Function(DonationBankField field) labelFor) {
    return bankLines
        .map((line) => '${labelFor(line.field)}: ${line.value}')
        .join('\n');
  }

  /// Shows a six-digit sort code as `00-00-00`. Other text is returned trimmed.
  static String formatSortCode(String raw) {
    final trimmed = raw.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) return trimmed;
    return '${digits.substring(0, 2)}-${digits.substring(2, 4)}-${digits.substring(4, 6)}';
  }

  factory DonationDetails.fromMap(String id, Map<String, dynamic> data) {
    return DonationDetails(
      id: id,
      accountName: (data['AccountName'] ?? '').toString(),
      sortCode: (data['SortCode'] ?? '').toString(),
      accountNumber: (data['AccountNumber'] ?? '').toString(),
      reference: (data['Reference'] ?? '').toString(),
      notes: _notesFrom(data['Notes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AccountName': _accountName,
      'SortCode': _sortCode,
      'AccountNumber': _accountNumber,
      'Reference': _reference,
      'Notes': List<String>.from(_notes),
    };
  }

  static List<String> _notesFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
