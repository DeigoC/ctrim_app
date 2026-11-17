import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/donation_details.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/permalink_app_bar_leading.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/paired_row_list.dart';
import '../../widgets/responsive_content.dart';

/// How to give by bank transfer. Opened from Personal and from About.
///
/// Reference: the CTRIM About tab (gradient intro, then [InfoSectionCard]s).
/// Content sits in [ResponsiveContent]. On a wide window the bank rows pair
/// (account name beside sort code, account number beside the reference). The
/// intro and the notes card stay full width.
class DonationsPage extends StatelessWidget {
  const DonationsPage({super.key, this.details = DonationDetails.published});

  final DonationDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lines = details.bankLines;
    final notes = details.notes;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        leading: PermalinkAppBarLeading.homeOrNull(context),
        title: Text(l10n.donationsTitle),
      ),
      body: ResponsiveContent(
        narrowPadding: 16,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _IntroBanner(
              title: l10n.donationsIntroTitle,
              body: l10n.donationsIntroBody,
            ),
            const SizedBox(height: 20),
            InfoSectionCard(
              icon: Icons.menu_book,
              title: l10n.donationsVerseTitle,
              subtitle: l10n.donationsVerseReference,
              content: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  l10n.donationsVerseBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InfoSectionCard(
              icon: Icons.account_balance_outlined,
              title: l10n.donationsBankTitle,
              subtitle: l10n.donationsBankSubtitle,
              content: lines.isEmpty
                  ? SizedBox(
                      width: double.infinity,
                      child: Text(
                        l10n.donationsBankPending,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : _BankDetails(
                      details: details,
                      l10n: l10n,
                      onCopy: (text) => _copy(context, text),
                    ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              InfoSectionCard(
                icon: Icons.sticky_note_2_outlined,
                title: l10n.donationsNotesTitle,
                subtitle: l10n.donationsNotesSubtitle,
                content: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < notes.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        Text(
                          notes[i],
                          style:
                              theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    await HapticFeedback.lightImpact();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.donationsCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.volunteer_activism_outlined,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankDetails extends StatelessWidget {
  const _BankDetails({
    required this.details,
    required this.l10n,
    required this.onCopy,
  });

  final DonationDetails details;
  final AppLocalizations l10n;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final wide = ResponsiveLayout.isWideScreenOf(context);
    final lines = details.bankLines;
    final tiles = [
      for (final line in lines)
        _BankDetailTile(
          label: _label(line.field),
          value: line.value,
          copyTooltip: l10n.donationsCopy,
          onCopy: () => onCopy(line.value),
        ),
    ];

    final Widget fields;
    if (wide && tiles.length > 1) {
      fields = PairedRowList(
        itemCount: tiles.length,
        spacing: 12,
        runSpacing: 12,
        itemBuilder: (context, index) => tiles[index],
      );
    } else {
      fields = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            tiles[i],
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fields,
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => onCopy(details.clipboardBlock(_label)),
          icon: const Icon(Icons.copy_rounded),
          label: Text(l10n.donationsCopyAll),
        ),
      ],
    );
  }

  String _label(DonationBankField field) {
    switch (field) {
      case DonationBankField.accountName:
        return l10n.donationsAccountName;
      case DonationBankField.sortCode:
        return l10n.donationsSortCode;
      case DonationBankField.accountNumber:
        return l10n.donationsAccountNumber;
      case DonationBankField.reference:
        return l10n.donationsReference;
    }
  }
}

class _BankDetailTile extends StatelessWidget {
  const _BankDetailTile({
    required this.label,
    required this.value,
    required this.copyTooltip,
    required this.onCopy,
  });

  final String label;
  final String value;
  final String copyTooltip;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: copyTooltip,
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
