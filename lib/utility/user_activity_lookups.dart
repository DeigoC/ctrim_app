import 'package:flutter/foundation.dart';

import '../firebase/db_managers/event_db_manager.dart';
import '../models/event/event_head.dart';
import '../models/user_activity_record.dart';
import 'app_context.dart';
import 'info_repository.dart';
import 'placeholder_user_permissions.dart';
import 'user_activity_subjects.dart';

/// Live names for activity rows, plus post heads fetched for this page only.
class UserActivityLookupData {
  const UserActivityLookupData({
    this.lookups = const {},
    this.fetchedHeads = const {},
  });

  static const UserActivityLookupData empty = UserActivityLookupData();

  final Map<UserActivityKind, ActivityTitleLookup> lookups;

  /// Heads outside [AppContext.eventHeads]. Do not add them to the session.
  final Map<String, EventHead> fetchedHeads;
}

class UserActivityLookupLoader {
  UserActivityLookupLoader._();

  /// Fail-soft: a source that cannot load is left out, so its rows fall back
  /// to the stored title and still open.
  static Future<UserActivityLookupData> load({
    required final List<UserActivityRecord> records,
    required final AppContext appContext,
    final InfoRepository? infoRepository,
    final EventHeadDBManager? headDBManager,
  }) async {
    if (records.isEmpty) return UserActivityLookupData.empty;
    final guest = appContext.isCurrentUserGuest;
    final viewer = appContext.currentUser;
    final info = infoRepository ?? InfoRepository();
    final lookups = <UserActivityKind, ActivityTitleLookup>{};

    final fetchedHeads = <String, EventHead>{};
    final unknownPosts = <String>{};
    final missingPostIds = UserActivitySubjects.postIds(records)
        .where((id) => appContext.headById(id) == null)
        .toList();
    if (missingPostIds.isNotEmpty) {
      final db = headDBManager ?? EventHeadDBManager();
      await Future.wait(missingPostIds.map((id) async {
        try {
          final head = await db.fetchHeadIfExists(id);
          if (head != null) fetchedHeads[id] = head;
        } catch (e) {
          debugPrint('Activity post lookup failed for $id: $e');
          unknownPosts.add(id);
        }
      }));
    }
    lookups[UserActivityKind.post] = (id) {
      final head = appContext.headById(id) ?? fetchedHeads[id];
      if (head != null) return head.title;
      return unknownPosts.contains(id) ? '' : null;
    };

    lookups[UserActivityKind.person] = (id) {
      final user = appContext.userById(id);
      if (user == null) return null;
      if (!canOpenPersonPermalink(user: user, viewer: viewer)) return null;
      return user.nameForViewer(guest: guest);
    };

    lookups[UserActivityKind.cellGroup] =
        (id) => appContext.cellGroupById(id)?.name;

    lookups[UserActivityKind.ministry] = (id) {
      final tag = appContext.tagById(id);
      if (tag == null || (guest && !tag.visibleToGuests)) return null;
      return tag.name;
    };

    lookups[UserActivityKind.postTag] =
        (id) => appContext.postTagById(id)?.name;

    lookups[UserActivityKind.location] = (id) {
      for (final location in appContext.allLocations) {
        if (location.id == id) return location.name;
      }
      return null;
    };

    Future<void> loadInfo<T>(
      final UserActivityKind kind,
      final Future<List<T>> Function() fetch,
      final String Function(T record) idOf,
      final String Function(T record) titleOf,
    ) async {
      if (!UserActivitySubjects.includesKind(records, kind)) return;
      try {
        final byId = {for (final r in await fetch()) idOf(r): titleOf(r)};
        lookups[kind] = (id) => byId[id];
      } catch (e) {
        debugPrint('Activity ${kind.name} lookup failed: $e');
      }
    }

    await Future.wait([
      loadInfo(
        UserActivityKind.church,
        info.fetchChurches,
        (r) => r.id,
        (r) => r.title,
      ),
      loadInfo(
        UserActivityKind.testimonial,
        info.fetchTestimonials,
        (r) => r.id,
        (r) => r.name,
      ),
      loadInfo(
        UserActivityKind.ctrimInfo,
        info.fetchCtrimInfo,
        (r) => r.id,
        (r) => r.title,
      ),
    ]);

    return UserActivityLookupData(lookups: lookups, fetchedHeads: fetchedHeads);
  }
}
