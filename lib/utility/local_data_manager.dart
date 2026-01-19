import 'dart:convert';
import 'dart:io';

import 'package:ctrim_app/models/post_template.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalDataManager {
  static bool _initialized = false;
  static const String _usersBox = 'users_cache';
  static const String _postTrackBox = 'post_track';
  static const String _postDataBox = 'post_data';
  static const String _templatesBox = 'templates';
  static const String _metadataBox = 'metadata';

  /// Initialize Hive - call this once at app startup
  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Open all required boxes
    await Future.wait([
      Hive.openBox(_usersBox),
      Hive.openBox(_postTrackBox),
      Hive.openBox(_postDataBox),
      Hive.openBox(_templatesBox),
      Hive.openBox(_metadataBox),
    ]);

    _initialized = true;
    debugPrint('LocalDataManager: Hive initialized');
  }

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
    final box = Hive.box(_usersBox);
    await box.put('users_data', content);
  }

  Future<List<String>> readUsers() async {
    final box = Hive.box(_usersBox);
    final String? content = box.get('users_data');
    if (content != null) {
      return LineSplitter().convert(content);
    }
    return List<String>.empty(growable: true);
  }

  Future<void> writeLastUsersFetch() async {
    final box = Hive.box(_metadataBox);
    await box.put('last_user_fetch', DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> readLastUserFetch() async {
    final box = Hive.box(_metadataBox);
    final int? timestamp = box.get('last_user_fetch');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // * Post Tracking
  Future<void> writePostTrack(final List<String> postTrack) async {
    final box = Hive.box(_postTrackBox);
    await box.put('post_track', postTrack);
  }

  Future<List<String>> readPostTrack() async {
    final box = Hive.box(_postTrackBox);
    final dynamic content = box.get('post_track');
    if (content != null && content is List) {
      return content.cast<String>();
    }
    return List<String>.empty(growable: true);
  }

  // * Post Data
  Future<void> writePostData(final String id, final String postData) async {
    debugPrint('writing post data for ID: $id');
    final box = Hive.box(_postDataBox);
    await box.put(id, postData);
  }

  Future<List<String>> readPostData(final String id) async {
    final box = Hive.box(_postDataBox);
    final String? content = box.get(id);
    if (content != null) {
      return LineSplitter().convert(content);
    }
    return List<String>.empty();
  }

  // delete the post data and the saved video thumbnails
  Future<void> deletePostData(final String id) async {
    final box = Hive.box(_postDataBox);
    await box.delete(id);
  }

  // * Post Templates
  Future<void> writePostTemplateData(final PostTemplate template) async {
    final box = Hive.box(_templatesBox);
    final Map<String, dynamic> data = template.toJson(true);
    data['id'] = template.id;
    await box.put(template.id, data);
  }

  Future<List<PostTemplate>> readAllPostTemplates() async {
    final box = Hive.box(_templatesBox);
    final List<PostTemplate> results = List.empty(growable: true);

    for (final key in box.keys) {
      if (key != 'last_update' && key != 'check_date') {
        final dynamic data = box.get(key);
        if (data != null && data is Map) {
          final Map<String, dynamic> contentJson = Map<String, dynamic>.from(data);
          results.add(PostTemplate.fromMap(true, contentJson['id'], contentJson));
        }
      }
    }

    return results;
  }

  Future<int> readLastPostTemplateUpdate() async {
    final box = Hive.box(_templatesBox);
    final int? value = box.get('last_update');
    if (value != null) {
      return value;
    }
    await writeLastPostTemplateUpdate(0);
    return 0;
  }

  Future<void> writeLastPostTemplateUpdate(final int value) async {
    final box = Hive.box(_templatesBox);
    await box.put('last_update', value);
  }

  Future<bool> haveCheckedTemplateUpdates() async {
    // also updates the date if needed - we'll clumsily just use the day of the week for now...
    final box = Hive.box(_templatesBox);
    final int? checkDay = box.get('check_date');
    final int today = DateTime.now().day;

    if (checkDay != null && checkDay == today) {
      debugPrint('We have already checked the post templates today');
      return true;
    }

    debugPrint('We have to check the post templates');
    await box.put('check_date', today);
    return false;
  }

  Future<void> clearPostTemplateDir() async {
    final box = Hive.box(_templatesBox);
    await box.clear();
  }
}
