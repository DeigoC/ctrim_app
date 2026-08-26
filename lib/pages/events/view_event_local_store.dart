import 'package:package_info_plus/package_info_plus.dart';

import '../../utility/event_context.dart';
import '../../utility/local_data_manager.dart';

/// First line of a cached post txt file: `{recentDateMs}-{appVersion}`.
bool cachedPostDataIsCurrent({
  required List<String> content,
  required int recentDateMs,
  required String appVersion,
}) {
  if (content.isEmpty) return false;
  final firstLine = content[0].split('-');
  if (firstLine.length != 2) return false;
  return int.parse(firstLine[0]) == recentDateMs && firstLine[1] == appVersion;
}

/// Returns cached post lines when the Hive copy matches [recentDate] and app version.
Future<List<String>> readCachedPostDataIfCurrent({
  required String postId,
  required DateTime recentDate,
}) async {
  final localDataManager = LocalDataManager();
  final packageInfo = await PackageInfo.fromPlatform();
  final content = await localDataManager.readPostData(postId);

  if (cachedPostDataIsCurrent(
    content: content,
    recentDateMs: recentDate.millisecondsSinceEpoch,
    appVersion: packageInfo.version,
  )) {
    return content;
  }
  return List.empty();
}

/// Writes the in-memory post to Hive. When [trackPost] is true, also records the id.
Future<void> writeCachedPostData(
  EventContext eventContext, {
  bool trackPost = false,
}) async {
  final localDataManager = LocalDataManager();
  final packageInfo = await PackageInfo.fromPlatform();
  final content = eventContext.transformPostToTxtFile(packageInfo.version);

  await localDataManager.writePostData(eventContext.id, content);
  if (!trackPost) return;

  final postTrack = await localDataManager.readPostTrack();
  if (!postTrack.contains(eventContext.id)) {
    postTrack.add(eventContext.id);
    await localDataManager.writePostTrack(postTrack);
  }
}
