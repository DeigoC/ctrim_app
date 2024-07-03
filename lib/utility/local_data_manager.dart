import 'dart:convert';
import 'dart:io';

import 'package:ctrim_app/models/post_template.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalDataManager {
  // ? Perform cache cleanup - to be run periodically?
  Future<void> cleanupCache(final String cacheDir) async {
    if (!kIsWeb) {
      try {
        final dir = Directory('$cacheDir/tmpImages');
        dir.delete(recursive: true);
      } catch (e) {
        debugPrint('something went wrong with cleaning up the cache: $e');
      }
    }
  }

  // * Users
  Future<void> writeUsersList(final String content) async {
    if (!kIsWeb) {
      final file = await _getUsersFile();
      await file.writeAsString(content);
    }
  }

  Future<List<String>> readUsers() async {
    if (!kIsWeb) {
      try {
        final file = await _getUsersFile();
        final content = await file.readAsLines();
        return content;
      } catch (e) {
        debugPrint('users file does not exist yet');
      }
    }
    return List<String>.empty(growable: true);
  }

  Future<File> _getUsersFile() async {
    final path = await _localPath;
    return File('$path/users.txt');
  }

  Future<void> writeLastUsersFetch() async {
    if (!kIsWeb) {
      final file = await _getLastUsersFetch();
      file.writeAsString(DateTime.now().millisecondsSinceEpoch.toString());
    }
  }

  Future<DateTime?> readLastUserFetch() async {
    if (!kIsWeb) {
      try {
        final file = await _getLastUsersFetch();
        final content = await file.readAsString();
        return DateTime.fromMillisecondsSinceEpoch(int.parse(content));
      } catch (e) {
        debugPrint('last user fetch file does not exist yet');
      }
    }
    return null;
  }

  Future<File> _getLastUsersFetch() async {
    final path = await _localPath;
    return File('$path/last_user_fetch.txt');
  }

  // * Post Tracking
  Future<void> writePostTrack(final List<String> postTrack) async {
    if (!kIsWeb) {
      final file = await _getPostTrackerFile();
      await file.writeAsString(postTrack.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(' ', ''));
    }
  }

  Future<List<String>> readPostTrack() async {
    if (!kIsWeb) {
      try {
        final file = await _getPostTrackerFile();
        final content = await file.readAsString();
        return content.split(',');
      } catch (e) {
        debugPrint('post track file does not exist yet');
      }
    }
    return List<String>.empty(growable: true);
  }

  Future<File> _getPostTrackerFile() async {
    final path = await _localPath;
    return File('$path/post_track.txt');
  }

  // * Post Data
  Future<void> writePostData(final String id, final String postData) async {
    debugPrint('writing post data for ID: $id');
    if (!kIsWeb) {
      final file = await _getPostFile(id);
      if (!await file.exists()) {
        file.create(recursive: true).then((createdFile) async => await createdFile.writeAsString(postData));
      } else {
        await file.writeAsString(postData);
      }
    }
  }

  Future<List<String>> readPostData(final String id) async {
    if (!kIsWeb) {
      try {
        final file = await _getPostFile(id);
        return await file.readAsLines();
      } catch (e) {
        debugPrint('file for post $id does not exist yet');
      }
    }
    return List<String>.empty();
  }

  // delete the post data and the saved video thumbnails
  Future<void> deletePostData(final String id) async {
    if (!kIsWeb) {
      try {
        final dir = await _getPostDirectory(id);
        dir.delete(recursive: true);
      } catch (e) {
        debugPrint('file for post $id does not exist yet');
      }
    }
  }

  Future<Directory> _getPostDirectory(String id) async {
    final path = await _localPath;
    return Directory('$path/posts/$id');
  }

  Future<File> _getPostFile(final String id) async {
    final path = await _localPath;
    return File('$path/posts/$id/post_data.txt');
  }

  // * Post Templates
  Future<void> writePostTemplateData(final PostTemplate template) async {
    final path = await _localPath;
    final File thisTemplateFile = File('$path/post_templates/${template.id}.json');

    final Map<String, dynamic> data = template.toJson(true);
    data['id'] = template.id;
    final String encodedJson = jsonEncode(data);
    await thisTemplateFile.writeAsString(encodedJson);
  }

  Future<List<PostTemplate>> readAllPostTemplates() async {
    final path = await _localPath;
    final Directory dir = Directory('$path/post_templates');
    final List<FileSystemEntity> entities = await dir.list().toList();
    entities
        .removeWhere((element) => element.path.contains('tracking.txt') || element.path.contains('check_tracking.txt'));
    final List<PostTemplate> results = List.empty(growable: true);

    for (final fileEntity in entities) {
      debugPrint('reading PostTemplate path: ${fileEntity.path}');
      final File tmpFile = File(fileEntity.path);
      final String contents = await tmpFile.readAsString();
      final Map<String, dynamic> contentJson = jsonDecode(contents);
      results.add(PostTemplate.fromMap(true, contentJson['id'], contentJson));
    }

    return results;
  }

  Future<int> readLastPostTemplateUpdate() async {
    final path = await _localPath;
    final Directory dir = Directory('$path/post_templates');
    if (!await dir.exists()) {
      await dir.create();
    }

    final File templateTrackingFile = File('$path/post_templates/tracking.txt');
    if (await templateTrackingFile.exists()) {
      final String valStr = await templateTrackingFile.readAsString();
      return int.parse(valStr);
    }
    writeLastPostTemplateUpdate(0);
    return 0;
  }

  Future<void> writeLastPostTemplateUpdate(final int value) async {
    final path = await _localPath;
    final File templateTrackingFile = File('$path/post_templates/tracking.txt');
    await templateTrackingFile.writeAsString(value.toString());
  }

  Future<bool> haveCheckedTemplateUpdates() async {
    // also updates the date if needed - we'll clumsily just use the day of the week for now...

    final path = await _localPath;
    final Directory postTemplateDir = Directory('$path/post_templates');
    if (!await postTemplateDir.exists()) {
      postTemplateDir.create();
    }

    final File checkFile = File('$path/post_templates/check_tracking.txt');
    if (await checkFile.exists() && await checkFile.readAsString() == DateTime.now().day.toString()) {
      debugPrint('We have already checked the post templates today');
      return true;
    }
    debugPrint('We have to check the post templates');
    checkFile.writeAsString(DateTime.now().day.toString());
    return false;
  }

  Future<void> clearPostTemplateDir() async {
    final path = await _localPath;
    final Directory dir = Directory('$path/post_templates');
    final List<FileSystemEntity> entities = await dir.list().toList();

    for (var entity in entities) {
      await entity.delete();
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
