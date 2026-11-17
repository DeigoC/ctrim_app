import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/auth_manager.dart';
import '../firebase/db_managers/user_db_manager.dart';
import '../models/event/event_head.dart';
import '../models/user.dart';
import 'app_context.dart';
import 'cache/directory_cache.dart';
import 'event_heads_repository.dart';
import 'placeholder_user_permissions.dart';
import 'user_schedule_service.dart';
import 'users_repository.dart';

/// One labelled slice of the opening load, in the order the bar can show them.
enum StartupLoadStep {
  opening,
  catalogs,
  posts,
  people,
  signingIn,
}

/// Determinate startup progress. [completed] climbs as each slice finishes.
typedef StartupProgressReporter = void Function({
  required int completed,
  required int total,
  required StartupLoadStep step,
});

/// Counts finished opening tasks and reports a determinate bar.
class StartupLoadProgress {
  StartupLoadProgress({
    required this.totalSteps,
    required StartupProgressReporter onProgress,
  }) : _onProgress = onProgress;

  final int totalSteps;
  final StartupProgressReporter _onProgress;

  int completedSteps = 0;

  /// Bulletin data is three steps. Stored credentials add sign-in.
  static int totalFor({required bool willSignIn}) => willSignIn ? 4 : 3;

  void report(StartupLoadStep step) {
    _onProgress(
      completed: completedSteps,
      total: totalSteps,
      step: step,
    );
  }

  void finishStep(StartupLoadStep step) {
    if (completedSteps < totalSteps) {
      completedSteps++;
    }
    report(step);
  }
}

/// Loads churches/groups, the bulletin, and people together, then optional
/// sign-in. Each slice reports when it finishes so the bar can move while the
/// others are still running. A failed slice still counts, and the shell opens
/// afterwards.
class EssentialStartupLoader {
  EssentialStartupLoader({
    required this.loadCatalogs,
    required this.loadPosts,
    required this.loadPeople,
    this.signIn,
  });

  final Future<void> Function() loadCatalogs;
  final Future<void> Function() loadPosts;
  final Future<void> Function() loadPeople;
  final Future<void> Function()? signIn;

  bool get willSignIn => signIn != null;

  Future<void> run({required StartupProgressReporter onProgress}) async {
    final progress = StartupLoadProgress(
      totalSteps: StartupLoadProgress.totalFor(willSignIn: willSignIn),
      onProgress: onProgress,
    );
    progress.report(StartupLoadStep.opening);

    await Future.wait([
      _finishAfter(loadCatalogs, StartupLoadStep.catalogs, progress),
      _finishAfter(loadPosts, StartupLoadStep.posts, progress),
      _finishAfter(loadPeople, StartupLoadStep.people, progress),
    ]);

    final signIn = this.signIn;
    if (signIn != null) {
      progress.report(StartupLoadStep.signingIn);
      await _finishAfter(signIn, StartupLoadStep.signingIn, progress);
    }
  }

  Future<void> _finishAfter(
    Future<void> Function() task,
    StartupLoadStep step,
    StartupLoadProgress progress,
  ) async {
    try {
      await task();
    } catch (e) {
      debugPrint('Startup step $step failed: $e');
    } finally {
      progress.finishStep(step);
    }
  }
}

/// Guest-first open: catalogues, posts, and people, then stored credentials.
///
/// The app is already on screen. Call this from [StartupGate] so the bar can
/// follow [onProgress]. Failures stay on the guest session.
Future<void> loadEssentialAppData({
  required AppContext app,
  required SharedPreferences preferences,
  required AuthManager authManager,
  required String? email,
  required String? password,
  required StartupProgressReporter onProgress,
  EventHeadsRepository? eventHeadsRepository,
  UsersRepository? usersRepository,
  DirectoryCacheCoordinator? directories,
}) {
  final headsRepository = eventHeadsRepository ?? EventHeadsRepository();
  final peopleRepository = usersRepository ?? UsersRepository();
  final directoryCache = directories ?? DirectoryCacheCoordinator.instance;

  final List<EventHead> heads = <EventHead>[];
  final List<User> allUsers = <User>[];
  final bool willSignIn =
      email != null && email != '' && password != null && password != '';

  return EssentialStartupLoader(
    loadCatalogs: () async {
      directoryCache.attach(app);
      await directoryCache.hydrateCatalogs(app);
      await directoryCache.revalidate(app: app, ignoreCooldown: true);
    },
    loadPosts: () async {
      final fetched = await headsRepository.fetchEventHeads();
      heads
        ..clear()
        ..addAll(fetched);
      app.setAllEventHeads(fetched);
      debugPrint('Successfully loaded ${fetched.length} posts for guest user');
    },
    loadPeople: () async {
      final usersResult = await peopleRepository.fetchUsersWithMeta();
      allUsers
        ..clear()
        ..addAll(usersResult.users);
      if (!usersResult.fromCache) {
        await preferences.setBool('fetchUserImages', true);
      }
      app.setAllUsers(usersResult.users);
    },
    signIn: willSignIn
        ? () => _signInFromStoredCredentials(
              app: app,
              authManager: authManager,
              email: email,
              password: password,
              heads: heads,
              allUsers: allUsers,
              headsRepository: headsRepository,
              peopleRepository: peopleRepository,
              directories: directoryCache,
            )
        : null,
  ).run(onProgress: onProgress);
}

Future<void> _signInFromStoredCredentials({
  required AppContext app,
  required AuthManager authManager,
  required String email,
  required String password,
  required List<EventHead> heads,
  required List<User> allUsers,
  required EventHeadsRepository headsRepository,
  required UsersRepository peopleRepository,
  required DirectoryCacheCoordinator directories,
}) async {
  debugPrint('Found stored credentials, attempting background login...');
  try {
    final authID = await authManager.loginAndReturnAuthID(email, password);
    final userDBManager = UserDBManager();
    final currentUser = await userDBManager.fetchUserByAuthID(authID);
    if (currentUser == null || !canSignInWithVolunteerProfile(currentUser)) {
      return;
    }

    var loadedHeads = List<EventHead>.from(heads);
    if (loadedHeads.isEmpty) {
      loadedHeads = await headsRepository.fetchEventHeads();
    }
    var loadedUsers = List<User>.from(allUsers);
    if (loadedUsers.isEmpty) {
      loadedUsers = await peopleRepository.fetchUsers();
    }

    currentUser.setRoles(await userDBManager.fetchUserRoles(currentUser.id));
    final scheduleService = UserScheduleService(userDBManager: userDBManager);
    await scheduleService.pruneStaleRoles(
      user: currentUser,
      eventHeads: loadedHeads,
    );

    loadedUsers.removeWhere((e) => e.id == currentUser.id);
    loadedUsers.add(currentUser);

    app.upgradeToAuthenticatedUser(
      user: currentUser,
      heads: loadedHeads,
      allUsers: loadedUsers,
    );
    await directories.seedFromLocalIfSignedIn();
    debugPrint(
        'Successfully upgraded guest to authenticated user: ${currentUser.forname}');
  } on FirebaseAuthException catch (e) {
    debugPrint('Background login failed: $e');
  }
}
