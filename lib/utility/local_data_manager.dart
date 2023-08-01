import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalDataManager {
  // * Users
  Future<void> writeUsersList(final String content) async {
    final file = await _getUsersFile();
    await file.writeAsString(content);
  }

  Future<List<String>> readUsers() async {
    try {
      final file = await _getUsersFile();
      final content = await file.readAsLines();
      return content;
    } catch (e) {
      debugPrint('users file does not exist yet');
    }
    return List<String>.empty(growable: true);
  }

  Future<File> _getUsersFile() async {
    final path = await _localPath;
    return File('$path/users.txt');
  }

  Future<void> writeLastUsersFetch() async {
    final file = await _getLastUsersFetch();
    file.writeAsString(DateTime.now().millisecondsSinceEpoch.toString());
  }

  Future<DateTime?> readLastUserFetch() async {
    try {
      final file = await _getLastUsersFetch();
      final content = await file.readAsString();
      return DateTime.fromMillisecondsSinceEpoch(int.parse(content));
    } catch (e) {
      debugPrint('last user fetch file does not exist yet');
    }
    return null;
  }

  Future<File> _getLastUsersFetch() async {
    final path = await _localPath;
    return File('$path/last_user_fetch.txt');
  }

  // * Post Tracking
  Future<void> writePostTrack(final List<String> postTrack) async {
    final file = await _getPostTrackerFile();
    await file.writeAsString(postTrack.toString().replaceAll('[', '').replaceAll(']', ''));
  }

  Future<List<String>> readPostTrack() async {
    try {
      final file = await _getPostTrackerFile();
      final content = await file.readAsString();
      return content.split(',');
    } catch (e) {
      debugPrint('post track file does not exist yet');
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
    final file = await _getPostFile(id);
    if (!await file.exists()) {
      file.create(recursive: true).then((createdFile) async => await createdFile.writeAsString(postData));
    } else {
      await file.writeAsString(postData);
    }
  }

  Future<List<String>> readPostData(final String id) async {
    try {
      final file = await _getPostFile(id);
      return await file.readAsLines();
    } catch (e) {
      debugPrint('file for post $id does not exist yet');
    }
    return List<String>.empty();
  }

  Future<File> _getPostFile(final String id) async {
    final path = await _localPath;
    return File('$path/posts/$id.txt');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
