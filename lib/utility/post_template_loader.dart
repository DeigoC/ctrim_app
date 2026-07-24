import '../firebase/db_managers/post_template_db_manager.dart';
import '../models/post_template.dart';
import 'local_data_manager.dart';

typedef PostTemplateLoadProgress = void Function({
  required int completed,
  required int total,
  required String message,
});

/// Loads post templates from Hive and/or Firestore, reporting progress for UI.
class PostTemplateLoader {
  PostTemplateLoader._();

  static Future<List<PostTemplate>> load({
    PostTemplateLoadProgress? onProgress,
    bool forceRemote = false,
  }) async {
    void report(int completed, int total, String message) {
      onProgress?.call(completed: completed, total: total, message: message);
    }

    final dataManager = LocalDataManager();

    if (!forceRemote) {
      report(0, 4, 'Checking local cache…');
      final checkedToday = await dataManager.haveCheckedTemplateUpdates();

      if (checkedToday) {
        report(2, 4, 'Reading saved templates…');
        final cached = await dataManager.readAllPostTemplates();
        if (cached.isEmpty) {
          report(1, 4, 'Cache empty — fetching from server…');
          await dataManager.clearPostTemplateDir();
          return load(onProgress: onProgress, forceRemote: true);
        }
        report(4, 4, 'Ready');
        return cached;
      }
    } else {
      report(0, 4, 'Fetching from server…');
    }

    report(1, 4, 'Checking for updates…');
    final dbManager = PostTemplateDBManager();
    final localUpdateValue = await dataManager.readLastPostTemplateUpdate();
    final dbUpdateValue = await dbManager.fetchLastUpdateTime();

    if (forceRemote || localUpdateValue != dbUpdateValue) {
      report(2, 4, 'Downloading templates…');
      final templates = await dbManager.fetchAllTemplates();

      if (templates.isEmpty) {
        await dataManager.writeLastPostTemplateUpdate(dbUpdateValue);
        report(4, 4, 'Ready');
        return templates;
      }

      for (var i = 0; i < templates.length; i++) {
        report(3, 4, 'Saving templates… (${i + 1} of ${templates.length})');
        await dataManager.writePostTemplateData(templates[i]);
      }

      // Mirror remote lastUpdate locally — do not bump it on fetch.
      await dataManager.writeLastPostTemplateUpdate(dbUpdateValue);
      report(4, 4, 'Ready');
      return templates;
    }

    report(2, 3, 'Reading saved templates…');
    final local = await dataManager.readAllPostTemplates();
    report(3, 3, 'Ready');
    return local;
  }
}
