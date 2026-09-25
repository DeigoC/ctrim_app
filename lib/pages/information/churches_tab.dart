import 'package:flutter/material.dart';

import '../../models/info/church_info.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_links.dart';
import '../../utility/church_hierarchy.dart';
import 'edit_info_body_page.dart';
import 'info_tab_widgets.dart';

class _ChurchListEntry {
  const _ChurchListEntry({required this.church, this.parentTitle});

  final ChurchInfo church;
  final String? parentTitle;
}

class ChurchesTab extends StatelessWidget {
  const ChurchesTab({
    super.key,
    required this.churchesFuture,
    required this.onRefresh,
  });

  final Future<List<ChurchInfo>> churchesFuture;
  final VoidCallback onRefresh;

  Future<List<_ChurchListEntry>> get _entriesFuture async {
    final all = await churchesFuture;
    return ChurchHierarchy.forChurchesTab(all)
        .map(
          (church) => _ChurchListEntry(
            church: church,
            parentTitle: ChurchHierarchy.parentOf(all, church)?.title,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return InfoSectionListTab<_ChurchListEntry>(
      future: _entriesFuture,
      onRefresh: onRefresh,
      storageKey: 'information_churches_tab',
      emptyMessage: 'No church information available yet.',
      addLabel: 'Add Church',
      addDescription: 'Create a new church information record.',
      onAdd: (context) => openInfoEditorAndRefresh(
        context: context,
        editor: EditInfoBodyPage.forChurch(),
        onRefresh: onRefresh,
      ),
      gridAspectRatio: (_) => 16 / 9,
      mobileItemHeight: MediaQuery.sizeOf(context).height * 0.36,
      itemBuilder: (context, entry, {required bool wide}) {
        final l10n = AppLocalizations.of(context)!;
        final church = entry.church;
        final subtitle = _churchListSubtitle(
          church: church,
          parentTitle: entry.parentTitle,
          l10n: l10n,
        );

        return InfoHeroOverlayCard(
          imageUrl: church.imgSrc,
          heroTag: 'info_church_${church.id}',
          onTap: () => openInfoDetailAndRefresh(
            context: context,
            open: () => AppLinks.openChurch(
              context,
              id: church.id,
              church: church,
            ),
            onRefresh: onRefresh,
          ),
          overlay: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (church.isOutreach) ...[
                _OutreachListTag(label: l10n.churchHubOutreachBadge),
                const SizedBox(height: 6),
              ],
              Text(
                church.title,
                style: TextStyle(
                  fontSize: wide ? 26 : 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: wide ? 14 : 16,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Line under the title on a Churches card.
///
/// A filled subtitle wins. Full churches with no subtitle show the title only.
/// Outreaches with no subtitle name their parent church.
String? _churchListSubtitle({
  required ChurchInfo church,
  required String? parentTitle,
  required AppLocalizations l10n,
}) {
  final summary = church.summary.trim();
  if (summary.isNotEmpty) return summary;
  if (!church.isOutreach) return null;
  final parent = parentTitle?.trim() ?? '';
  if (parent.isNotEmpty) return l10n.churchesTabOutreachOf(parent);
  return l10n.churchHubOutreachBadge;
}

class _OutreachListTag extends StatelessWidget {
  const _OutreachListTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
