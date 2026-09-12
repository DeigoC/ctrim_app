import '../models/info/church_info.dart';

/// Parent/child helpers for full churches vs outreaches.
class ChurchHierarchy {
  ChurchHierarchy._();

  /// Top-level hubs only (Churches list historically).
  static List<ChurchInfo> fullChurches(final Iterable<ChurchInfo> churches) {
    return churches.where((c) => c.isFullChurch).toList();
  }

  /// Full churches and outreaches for the Churches tab, display order then title.
  static List<ChurchInfo> forChurchesTab(final Iterable<ChurchInfo> churches) {
    final list = List<ChurchInfo>.from(churches);
    list.sort((a, b) {
      final order = a.displayOrder.compareTo(b.displayOrder);
      if (order != 0) return order;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return list;
  }

  /// Outreaches whose [ChurchInfo.parentChurchId] is [parentId], display order.
  static List<ChurchInfo> outreachesOf(
    final Iterable<ChurchInfo> churches,
    final String parentId,
  ) {
    final id = parentId.trim();
    if (id.isEmpty) return const [];
    final children = churches
        .where((c) => c.isOutreach && c.parentChurchId == id)
        .toList();
    children.sort((a, b) {
      final order = a.displayOrder.compareTo(b.displayOrder);
      if (order != 0) return order;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return children;
  }

  static ChurchInfo? parentOf(
    final Iterable<ChurchInfo> churches,
    final ChurchInfo church,
  ) {
    if (!church.hasParentChurch) return null;
    for (final candidate in churches) {
      if (candidate.id == church.parentChurchId) return candidate;
    }
    return null;
  }

  /// Full churches that may parent an outreach (excludes [excludingId]).
  static List<ChurchInfo> eligibleParents({
    required final Iterable<ChurchInfo> churches,
    final String? excludingId,
  }) {
    return fullChurches(churches)
        .where((c) => excludingId == null || c.id != excludingId)
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  static bool hasOutreaches(
    final Iterable<ChurchInfo> churches,
    final String churchId,
  ) {
    return outreachesOf(churches, churchId).isNotEmpty;
  }

  /// Promote an outreach: full church, no parent. Caller sets location.
  static void applyPromote(final ChurchInfo church) {
    church.setKind(ChurchKind.church);
    church.setParentChurchId('');
  }

  /// Demote a full church under [parentId]. Clears location catalogue slot.
  static void applyDemote(
    final ChurchInfo church, {
    required final String parentId,
  }) {
    church.setKind(ChurchKind.outreach);
    church.setParentChurchId(parentId);
    church.setLocation('');
  }

  /// Why demote is blocked, or null if allowed.
  static String? demoteBlockReason({
    required final ChurchInfo church,
    required final Iterable<ChurchInfo> churches,
  }) {
    if (!church.isFullChurch) {
      return 'Only a full church can be demoted to an outreach.';
    }
    if (hasOutreaches(churches, church.id)) {
      return 'Promote or reassign this church’s outreaches first.';
    }
    return null;
  }

  /// Why promote is blocked, or null if allowed.
  static String? promoteBlockReason(final ChurchInfo church) {
    if (!church.isOutreach) {
      return 'Only an outreach can be promoted to a full church.';
    }
    return null;
  }

  /// Validation before save for kind/parent/location rules.
  static String? validateForSave({
    required final ChurchInfo draft,
    required final Iterable<ChurchInfo> churches,
  }) {
    if (draft.isFullChurch) {
      if (draft.parentChurchId.trim().isNotEmpty) {
        return 'A full church cannot have a parent church.';
      }
      if (draft.location.trim().isEmpty) {
        return 'A full church needs a location.';
      }
      return null;
    }

    final parentId = draft.parentChurchId.trim();
    if (parentId.isEmpty) {
      return 'An outreach needs a parent church.';
    }
    if (parentId == draft.id) {
      return 'An outreach cannot be its own parent.';
    }
    ChurchInfo? parent;
    for (final candidate in churches) {
      if (candidate.id == parentId) {
        parent = candidate;
        break;
      }
    }
    if (parent == null) {
      return 'Parent church was not found.';
    }
    if (!parent.isFullChurch) {
      return 'Parent must be a full church, not another outreach.';
    }
    return null;
  }
}
