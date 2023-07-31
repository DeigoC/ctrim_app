import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalDataManager {
  // * Post Tracking
  Future<void> setPostTrack(List<String> postTrack) async {
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
  Future<void> setPostData(String id, String postData) async {
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

  Future<File> _getPostFile(String id) async {
    final path = await _localPath;
    return File('$path/posts/$id.txt');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
