import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/team_rota.dart';

/// Short index of the next empty ministry-schedule slots.
class TeamRotaGapsCard extends StatelessWidget {
  const TeamRotaGapsCard({
    super.key,
    required this.gaps,
    required this.onGapTap,
  });

  final List<TeamRotaGap> gaps;
  final void Function(TeamRotaGap gap) onGapTap;

  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teamRotaNeedsPeople,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (gaps.isEmpty)
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.teamRotaGapsCovered,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              )
            else
              for (var i = 0; i < gaps.length; i++) ...[
                if (i > 0) const SizedBox(height: 4),
                _GapRow(
                  gap: gaps[i],
                  dateLabel: _dateLabel(l10n, gaps[i]),
                  onTap: () => onGapTap(gaps[i]),
                ),
              ],
          ],
        ),
      ),
    );
  }

  static String _dateLabel(AppLocalizations l10n, TeamRotaGap gap) {
    final date = gap.post.head.eventDate;
    final when = date != null
        ? _eventDateFormat.format(date)
        : l10n.personalScheduleDateTbc;
    return '$when · ${gap.post.head.title}';
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({
    required this.gap,
    required this.dateLabel,
    required this.onTap,
  });

  final TeamRotaGap gap;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = gap.role['title'] as String? ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
