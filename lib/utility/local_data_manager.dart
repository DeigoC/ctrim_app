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
  static const String _imagesCacheBox = 'images_cache';

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
      Hive.openBox(_imagesCacheBox),
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
    final dynamic value = box.get('last_user_fetch');
    if (value != null) {
      // Handle both int and string (for old SharedPreferences data)
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
        } catch (e) {
          debugPrint('Error parsing last_user_fetch: $e');
        }
      }
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
    final dynamic value = box.get('last_update');
    if (value != null) {
      // Handle both int and string (for old file-based data)
      if (value is int) {
        return value;
      } else if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          debugPrint('Error parsing last_update: $e');
        }
      }
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
    final dynamic checkDay = box.get('check_date');
    final int today = DateTime.now().day;

    if (checkDay != null) {
      // Handle both int and string (for old file-based data)
      int? dayValue;
      if (checkDay is int) {
        dayValue = checkDay;
      } else if (checkDay is String) {
        try {
          dayValue = int.parse(checkDay);
        } catch (e) {
          debugPrint('Error parsing check_date: $e');
        }
      }

      if (dayValue == today) {
        debugPrint('We have already checked the post templates today');
        return true;
      }
    }

    debugPrint('We have to check the post templates');
    await box.put('check_date', today);
    return false;
  }

  Future<void> clearPostTemplateDir() async {
    final box = Hive.box(_templatesBox);
    await box.clear();
  }

  // * User Profile Images (cross-platform)
  /// Save user profile image bytes to cache
  Future<void> writeUserImage(final String userId, final Uint8List imageBytes) async {
    final box = Hive.box(_imagesCacheBox);
    await box.put('user_$userId', imageBytes);
  }

  /// Read user profile image bytes from cache
  Future<Uint8List?> readUserImage(final String userId) async {
    final box = Hive.box(_imagesCacheBox);
    final dynamic data = box.get('user_$userId');
    if (data != null && data is Uint8List) {
      return data;
    }
    return null;
  }

  /// Delete user profile image from cache
  Future<void> deleteUserImage(final String userId) async {
    final box = Hive.box(_imagesCacheBox);
    await box.delete('user_$userId');
  }

  /// Check if user profile image exists in cache
  Future<bool> hasUserImage(final String userId) async {
    final box = Hive.box(_imagesCacheBox);
    return box.containsKey('user_$userId');
  }

  /// Clear all cached images
  Future<void> clearAllImages() async {
    final box = Hive.box(_imagesCacheBox);
    await box.clear();
  }

  // * Media Images Cache
  /// Save media image bytes to cache
  Future<void> writeMediaImage(final String mediaKey, final Uint8List imageBytes) async {
    final box = Hive.box(_imagesCacheBox);
    await box.put('media_$mediaKey', imageBytes);
  }

  /// Read media image bytes from cache
  Future<Uint8List?> readMediaImage(final String mediaKey) async {
    final box = Hive.box(_imagesCacheBox);
    final dynamic data = box.get('media_$mediaKey');
    if (data != null && data is Uint8List) {
      return data;
    }
    return null;
  }

  /// Delete media image from cache
  Future<void> deleteMediaImage(final String mediaKey) async {
    final box = Hive.box(_imagesCacheBox);
    await box.delete('media_$mediaKey');
  }

  /// Check if media image exists in cache
  Future<bool> hasMediaImage(final String mediaKey) async {
    final box = Hive.box(_imagesCacheBox);
    return box.containsKey('media_$mediaKey');
  }

  // * Video Thumbnails Cache
  /// Save video thumbnail bytes to cache
  Future<void> writeVideoThumbnail(final String postId, final String videoKey, final Uint8List imageBytes) async {
    final box = Hive.box(_imagesCacheBox);
    await box.put('video_${postId}_$videoKey', imageBytes);
  }

  /// Read video thumbnail bytes from cache
  Future<Uint8List?> readVideoThumbnail(final String postId, final String videoKey) async {
    final box = Hive.box(_imagesCacheBox);
    final dynamic data = box.get('video_${postId}_$videoKey');
    if (data != null && data is Uint8List) {
      return data;
    }
    return null;
  }

  /// Delete video thumbnail from cache
  Future<void> deleteVideoThumbnail(final String postId, final String videoKey) async {
    final box = Hive.box(_imagesCacheBox);
    await box.delete('video_${postId}_$videoKey');
  }

  /// Check if video thumbnail exists in cache
  Future<bool> hasVideoThumbnail(final String postId, final String videoKey) async {
    final box = Hive.box(_imagesCacheBox);
    return box.containsKey('video_${postId}_$videoKey');
  }
}
