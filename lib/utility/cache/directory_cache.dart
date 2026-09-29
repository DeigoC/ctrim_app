import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../firebase/db_managers/id_tracker.dart';
import '../../firebase/db_managers/info_db_manager.dart';
import '../../firebase/db_managers/post_tag_db_manager.dart';
import '../../firebase/db_managers/user_location_db_manager.dart';
import '../../firebase/db_managers/user_tag_db_manager.dart';
import '../app_context.dart';
import 'collection_cache_policy.dart';
import 'directory_catalog_store.dart';
import 'local_data_manager.dart';
import 'refresh_cooldown.dart';

/// Session check for catalogues and information records.
///
/// Screens paint Hive immediately. This reads `id_tracker/directories` once,
/// refreshes only collections whose watermark moved, and remembers that check
/// until the app resumes.
class DirectoryCacheCoordinator extends ChangeNotifier {
  DirectoryCacheCoordinator({
    LocalDataManager? localDataManager,
    IDTrackerDBManager? idTracker,
    DirectoryCatalogStore? store,
    PostTagDBManager? postTags,
    UserLocationDBManager? locations,
    UserTagDBManager? userTags,
    CellGroupDBManager? cellGroups,
    ChurchInfoDBManager? churches,
    TestimonialInfoDBManager? testimonials,
    CtrimInfoDBManager? ctrimInfo,
    ChurchPageDBManager? churchPages,
  })  : _local = localDataManager ?? LocalDataManager(),
        _tracker = idTracker ?? IDTrackerDBManager(),
        _store = store ??
            DirectoryCatalogStore(
              localDataManager: localDataManager,
              idTracker: idTracker,
            ),
        _postTags = postTags ?? PostTagDBManager(),
        _locations = locations ?? UserLocationDBManager(),
        _userTags = userTags ?? UserTagDBManager(),
        _cellGroups = cellGroups ?? CellGroupDBManager(),
        _churches = churches ?? ChurchInfoDBManager(),
        _testimonials = testimonials ?? TestimonialInfoDBManager(),
        _ctrimInfo = ctrimInfo ?? CtrimInfoDBManager(),
        _churchPages = churchPages ?? ChurchPageDBManager();

  static final DirectoryCacheCoordinator instance = DirectoryCacheCoordinator();

  static const List<String> _infoFields = [
    IDTrackerDBManager.churchesField,
    IDTrackerDBManager.testimonialsField,
    IDTrackerDBManager.ctrimInfoField,
  ];

  final LocalDataManager _local;
  final IDTrackerDBManager _tracker;
  final DirectoryCatalogStore _store;
  final PostTagDBManager _postTags;
  final UserLocationDBManager _locations;
  final UserTagDBManager _userTags;
  final CellGroupDBManager _cellGroups;
  final ChurchInfoDBManager _churches;
  final TestimonialInfoDBManager _testimonials;
  final CtrimInfoDBManager _ctrimInfo;
  final ChurchPageDBManager _churchPages;

  final Set<String> _validated = {};
  final Set<String> _pagesChecked = {};
  final Map<String, Future<void>> _pageChecks = {};

  AppContext? _app;
  Future<void>? _inflight;
  DateTime? _lastCheck;
  int epoch = 0;
  bool initialPassCompleted = false;

  final Completer<void> _initialCompleter = Completer<void>();

  Future<void> get catalogsReady => _initialCompleter.future;

  bool isValidated(final String sectionKey) => _validated.contains(sectionKey);

  bool isPagesChecked(final String churchId) =>
      _pagesChecked.contains(churchId);

  void markValidated(final String sectionKey) => _validated.add(sectionKey);

  void markPagesChecked(final String churchId) => _pagesChecked.add(churchId);

  void attach(final AppContext app) => _app = app;

  void notifyInfoChanged() {
    epoch++;
    notifyListeners();
  }

  Future<void> hydrateCatalogs(final AppContext app) async {
    _app = app;
    final postTags = await _store.readPostTags();
    if (postTags.isNotEmpty) app.setAllPostTags(postTags);
    final locations = await _store.readUserLocations();
    if (locations.isNotEmpty) app.setAllLocations(locations);
    final userTags = await _store.readUserTags();
    if (userTags.isNotEmpty) app.setAllTags(userTags);
    final groups = await _store.readCellGroups();
    if (groups.isNotEmpty) app.setAllCellGroups(groups);
  }

  /// Compares the shared watermark and refreshes stale collections.
  ///
  /// Pass [ignoreCooldown] for startup. Resume uses the two-minute cooldown.
  Future<void> revalidate({
    AppContext? app,
    bool ignoreCooldown = false,
  }) {
    if (app != null) _app = app;
    final target = _app;
    if (target == null) return Future.value();

    final settled = _validated.containsAll(IDTrackerDBManager.directoryFields);
    if (!ignoreCooldown && settled && !_cooldownElapsed) {
      return Future.value();
    }

    final existing = _inflight;
    if (existing != null) return existing;

    final run = _revalidateBody(target).whenComplete(() {
      _inflight = null;
      _lastCheck = DateTime.now();
      _finishInitial();
    });
    _inflight = run;
    return run;
  }

  Future<void> forceRefreshCellGroups(final AppContext app) async {
    _app = app;
    await _guard('cell groups', () => _downloadCellGroups(app));
    _validated.add(IDTrackerDBManager.cellGroupsField);
  }

  /// First open of a church compares `pagesLastUpdate` without blocking paint
  /// when pages are already in Hive.
  Future<void> revalidateChurchPages(final String churchId) {
    if (_pagesChecked.contains(churchId)) return Future.value();
    return _pageChecks.putIfAbsent(churchId, () async {
      final ok = await _checkChurchPages(churchId);
      if (ok) {
        _pagesChecked.add(churchId);
      } else {
        _pageChecks.remove(churchId);
      }
    });
  }

  /// After a signed-in upgrade, publish local stamps if the tracker doc is
  /// still missing so later guest sessions can skip the full download.
  Future<void> seedFromLocalIfSignedIn() => _seedFromLocalIfSignedIn();

  Future<void> _revalidateBody(final AppContext app) async {
    DirectoryWatermarks watermarks;
    try {
      watermarks = await _tracker.fetchDirectoryWatermarks();
    } catch (e) {
      debugPrint('DirectoryCache: watermark read failed: $e');
      return;
    }

    if (!watermarks.exists) {
      final seeded = await _seedFromLocalIfSignedIn();
      if (seeded) {
        try {
          watermarks = await _tracker.fetchDirectoryWatermarks();
        } catch (e) {
          debugPrint('DirectoryCache: watermark reread failed: $e');
        }
      }
    }

    if (!watermarks.exists) {
      await _refreshWithoutTracker(app);
      await _seedFromLocalIfSignedIn();
      return;
    }

    await _refreshAgainst(app, watermarks);
  }

  Future<void> _refreshWithoutTracker(final AppContext app) async {
    await _guard('post tags', () => _downloadPostTags(app));
    await _guard('user locations', () => _downloadLocations(app));
    await _guard('user tags', () => _downloadUserTags(app));
    await _guard('cell groups', () => _downloadCellGroups(app));
    var infoChanged = false;
    for (final field in _infoFields) {
      final changed = await _guardInfo(field, () => _refreshInfoLegacy(field));
      infoChanged = infoChanged || changed;
    }
    if (infoChanged) notifyInfoChanged();
  }

  Future<void> _refreshAgainst(
    final AppContext app,
    final DirectoryWatermarks watermarks,
  ) async {
    await _guard(
      'post tags',
      () => _refreshCatalog(
        field: IDTrackerDBManager.postTagsField,
        remote: watermarks.valueOf(IDTrackerDBManager.postTagsField),
        hasSnapshot: () async {
          final rows = await _store.readPostTags();
          return rows.isNotEmpty;
        },
        download: () => _downloadPostTags(app),
      ),
    );
    await _guard(
      'user locations',
      () => _refreshCatalog(
        field: IDTrackerDBManager.userLocationsField,
        remote: watermarks.valueOf(IDTrackerDBManager.userLocationsField),
        hasSnapshot: () async {
          final rows = await _store.readUserLocations();
          return rows.isNotEmpty;
        },
        download: () => _downloadLocations(app),
      ),
    );
    await _guard(
      'user tags',
      () => _refreshCatalog(
        field: IDTrackerDBManager.userTagsField,
        remote: watermarks.valueOf(IDTrackerDBManager.userTagsField),
        hasSnapshot: () async {
          final rows = await _store.readUserTags();
          return rows.isNotEmpty;
        },
        download: () => _downloadUserTags(app),
      ),
    );
    await _guard(
      'cell groups',
      () => _refreshCatalog(
        field: IDTrackerDBManager.cellGroupsField,
        remote: watermarks.valueOf(IDTrackerDBManager.cellGroupsField),
        hasSnapshot: () async {
          final rows = await _store.readCellGroups();
          return rows.isNotEmpty;
        },
        download: () => _downloadCellGroups(app),
      ),
    );

    var infoChanged = false;
    for (final field in _infoFields) {
      final changed = await _guardInfo(
        field,
        () => _refreshInfoField(field, watermarks),
      );
      infoChanged = infoChanged || changed;
    }
    if (infoChanged) notifyInfoChanged();
  }

  Future<void> _refreshCatalog({
    required String field,
    required int remote,
    required Future<bool> Function() hasSnapshot,
    required Future<void> Function() download,
  }) async {
    final local = await _local.readCollectionLastUpdate(field);
    final hasCache = await hasSnapshot() || local > 0;
    if (shouldUseLocalCollectionCache(
      forceRefresh: false,
      hasCachedRecords: hasCache,
      remoteLastUpdate: remote,
      localLastUpdate: local,
    )) {
      _validated.add(field);
      return;
    }
    await download();
    _validated.add(field);
  }

  Future<bool> _refreshInfoField(
    final String field,
    final DirectoryWatermarks watermarks,
  ) async {
    var remote = watermarks.valueOf(field);
    if (remote <= 0) {
      remote = await _legacyInfoStamp(field);
      if (remote > 0) {
        await _tracker.trySetDirectoryLastUpdate(field, remote);
      }
    }
    return _refreshInfo(field, remote);
  }

  Future<bool> _refreshInfoLegacy(final String field) async {
    final remote = await _legacyInfoStamp(field);
    return _refreshInfo(field, remote);
  }

  /// Returns true when Hive was replaced.
  Future<bool> _refreshInfo(final String field, final int remote) async {
    final local = await _local.readCollectionLastUpdate(field);
    final hasCache = await _infoHasRows(field) || local > 0;
    if (shouldUseLocalCollectionCache(
      forceRefresh: false,
      hasCachedRecords: hasCache,
      remoteLastUpdate: remote,
      localLastUpdate: local,
    )) {
      _validated.add(field);
      return false;
    }
    await _downloadInfo(field);
    _validated.add(field);
    return true;
  }

  Future<int> _legacyInfoStamp(final String field) {
    switch (field) {
      case IDTrackerDBManager.testimonialsField:
        return _testimonials.fetchLastUpdate();
      case IDTrackerDBManager.ctrimInfoField:
        return _ctrimInfo.fetchLastUpdate();
      default:
        return _churches.fetchLastUpdate();
    }
  }

  Future<bool> _infoHasRows(final String field) async {
    switch (field) {
      case IDTrackerDBManager.testimonialsField:
        return (await _local.readAllTestimonialInfo()).isNotEmpty;
      case IDTrackerDBManager.ctrimInfoField:
        return (await _local.readAllCtrimInfo()).isNotEmpty;
      default:
        return (await _local.readAllChurchInfo()).isNotEmpty;
    }
  }

  Future<void> _downloadInfo(final String field) async {
    switch (field) {
      case IDTrackerDBManager.testimonialsField:
        final records = await _testimonials.fetchAll();
        await _local.clearTestimonialInfo();
        for (final record in records) {
          await _local.writeTestimonialInfoData(record);
        }
        await _writeStamp(field, await _testimonials.fetchLastUpdate());
      case IDTrackerDBManager.ctrimInfoField:
        final records = await _ctrimInfo.fetchAll();
        await _local.clearCtrimInfo();
        for (final record in records) {
          await _local.writeCtrimInfoData(record);
        }
        await _writeStamp(field, await _ctrimInfo.fetchLastUpdate());
      default:
        final records = await _churches.fetchAll();
        await _local.clearChurchInfo();
        for (final record in records) {
          await _local.writeChurchInfoData(record);
        }
        await _writeStamp(field, await _churches.fetchLastUpdate());
    }
  }

  Future<void> _downloadPostTags(final AppContext app) async {
    final tags = await _postTags.fetchAllTags();
    final remote = (await _tracker.fetchDirectoryWatermarks())
        .valueOf(IDTrackerDBManager.postTagsField);
    await _store.replacePostTags(tags, remoteLastUpdate: remote);
    app.setAllPostTags(tags);
  }

  Future<void> _downloadLocations(final AppContext app) async {
    final locations = await _locations.fetchAllLocations();
    final remote = (await _tracker.fetchDirectoryWatermarks())
        .valueOf(IDTrackerDBManager.userLocationsField);
    await _store.replaceUserLocations(locations, remoteLastUpdate: remote);
    app.setAllLocations(locations);
  }

  Future<void> _downloadUserTags(final AppContext app) async {
    final tags = await _userTags.fetchAllTags();
    final remote = (await _tracker.fetchDirectoryWatermarks())
        .valueOf(IDTrackerDBManager.userTagsField);
    await _store.replaceUserTags(tags, remoteLastUpdate: remote);
    app.setAllTags(tags);
  }

  Future<void> _downloadCellGroups(final AppContext app) async {
    final groups = await _cellGroups.fetchAllGroups();
    final remote = (await _tracker.fetchDirectoryWatermarks())
        .valueOf(IDTrackerDBManager.cellGroupsField);
    await _store.replaceCellGroups(groups, remoteLastUpdate: remote);
    app.setAllCellGroups(groups);
  }

  Future<void> _writeStamp(final String field, final int remote) async {
    var stamp = remote;
    if (stamp <= 0) {
      stamp = await _tracker.tryTouchDirectoryLastUpdate(field);
    }
    if (stamp <= 0) {
      stamp = DateTime.now().millisecondsSinceEpoch;
    }
    await _local.writeCollectionLastUpdate(field, stamp);
  }

  Future<bool> _checkChurchPages(final String churchId) async {
    try {
      final key = LocalDataManager.churchPagesSectionKey(churchId);
      final remote = await _churchPages.fetchLastUpdate(churchId);
      final local = await _local.readInfoCollectionLastUpdate(key);
      final cached = await _local.readChurchPages(churchId);
      final hasCache = cached.isNotEmpty || local > 0;
      if (hasCache && (remote == local || (remote <= 0 && local > 0))) {
        return true;
      }
      final records = await _churchPages.fetchAll(churchId);
      await _local.clearChurchPages(churchId);
      for (final page in records) {
        await _local.writeChurchPageData(page);
      }
      final stamp = remote > 0 ? remote : DateTime.now().millisecondsSinceEpoch;
      await _local.writeInfoCollectionLastUpdate(key, stamp);
      notifyInfoChanged();
      return true;
    } catch (e) {
      debugPrint('DirectoryCache: church pages $churchId failed: $e');
      return false;
    }
  }

  Future<bool> _seedFromLocalIfSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) return false;
    try {
      final existing = await _tracker.fetchDirectoryWatermarks();
      if (existing.exists) return false;
    } catch (e) {
      debugPrint('DirectoryCache: seed check failed: $e');
      return false;
    }
    final values = <String, int>{};
    for (final field in IDTrackerDBManager.directoryFields) {
      final local = await _local.readCollectionLastUpdate(field);
      if (local > 0) values[field] = local;
    }
    if (values.isEmpty) return false;
    return _tracker.trySeedDirectoryWatermarks(values);
  }

  Future<void> _guard(
      final String label, final Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('DirectoryCache: $label failed: $e');
    }
  }

  /// True when the info section was rewritten.
  Future<bool> _guardInfo(
    final String field,
    final Future<bool> Function() action,
  ) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('DirectoryCache: $field failed: $e');
      return false;
    }
  }

  bool get _cooldownElapsed {
    final last = _lastCheck;
    if (last == null) return true;
    return hasRefreshCooldownElapsed(
      now: DateTime.now(),
      lastRefreshMs: last.millisecondsSinceEpoch,
    );
  }

  void _finishInitial() {
    if (initialPassCompleted) return;
    initialPassCompleted = true;
    if (!_initialCompleter.isCompleted) {
      _initialCompleter.complete();
    }
  }
}
