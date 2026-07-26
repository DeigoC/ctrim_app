import 'dart:convert';
import 'dart:io';

import 'package:ctrim_app/models/info/church_info.dart';
import 'package:ctrim_app/models/info/ctrim_info.dart';
import 'package:ctrim_app/models/info/testimonial_info.dart';
import 'package:ctrim_app/models/post_template.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalDataManager {
  static bool _initialized = false;
  static const String _usersBox = 'users_cache';
  static const String _postTrackBox = 'post_track';
  static const String _postDataBox = 'post_data';
  static const String _templatesBox = 'templates';
  static const String _churchInfoBox = 'church_info';
  static const String _ctrimInfoBox = 'ctrim_info';
  static const String _testimonialInfoBox = 'testimonial_info';
  static const String _metadataBox = 'metadata';
  static const String _imagesCacheBox = 'images_cache';
  static const String _cacheTimestampsBox = 'cache_timestamps';

  // Cache size limits (in bytes)
  static const int maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int warningCacheSizeBytes = 40 * 1024 * 1024; // 40MB
  static const double evictionPercentage = 0.25; // Remove 25% when limit hit

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
      Hive.openBox(_churchInfoBox),
      Hive.openBox(_ctrimInfoBox),
      Hive.openBox(_testimonialInfoBox),
      Hive.openBox(_metadataBox),
      Hive.openBox(_imagesCacheBox),
      Hive.openBox(_cacheTimestampsBox),
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
          try {
            final Map<String, dynamic> contentJson = Map<String, dynamic>.from(data);
            results.add(PostTemplate.fromMap(true, contentJson['id'], contentJson));
          } catch (e) {
            debugPrint('Error deserializing template $key: $e - skipping');
            // Skip corrupted/outdated cached templates
          }
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

  // * Information content cache
  Future<void> writeChurchInfoData(final ChurchInfo info) async {
    final box = Hive.box(_churchInfoBox);
    await box.put(info.id, info.toCacheJson());
  }

  Future<ChurchInfo?> readChurchInfo(final String id) async {
    final box = Hive.box(_churchInfoBox);
    final dynamic data = box.get(id);
    if (data is Map) {
      return ChurchInfo.fromMap(id, Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<ChurchInfo>> readAllChurchInfo() async {
    final box = Hive.box(_churchInfoBox);
    return _readAllInfoRecords<ChurchInfo>(box, (id, data) => ChurchInfo.fromMap(id, data));
  }

  Future<void> clearChurchInfo() async {
    final box = Hive.box(_churchInfoBox);
    await box.clear();
  }

  Future<void> deleteChurchInfoData(final String id) async {
    final box = Hive.box(_churchInfoBox);
    await box.delete(id);
  }

  Future<void> writeCtrimInfoData(final CtrimInfo info) async {
    final box = Hive.box(_ctrimInfoBox);
    await box.put(info.id, info.toCacheJson());
  }

  Future<CtrimInfo?> readCtrimInfo(final String id) async {
    final box = Hive.box(_ctrimInfoBox);
    final dynamic data = box.get(id);
    if (data is Map) {
      return CtrimInfo.fromMap(id, Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<CtrimInfo>> readAllCtrimInfo() async {
    final box = Hive.box(_ctrimInfoBox);
    return _readAllInfoRecords<CtrimInfo>(box, (id, data) => CtrimInfo.fromMap(id, data));
  }

  Future<void> clearCtrimInfo() async {
    final box = Hive.box(_ctrimInfoBox);
    await box.clear();
  }

  Future<void> deleteCtrimInfoData(final String id) async {
    final box = Hive.box(_ctrimInfoBox);
    await box.delete(id);
  }

  Future<void> writeTestimonialInfoData(final TestimonialInfo info) async {
    final box = Hive.box(_testimonialInfoBox);
    await box.put(info.id, info.toCacheJson());
  }

  Future<TestimonialInfo?> readTestimonialInfo(final String id) async {
    final box = Hive.box(_testimonialInfoBox);
    final dynamic data = box.get(id);
    if (data is Map) {
      return TestimonialInfo.fromMap(id, Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<TestimonialInfo>> readAllTestimonialInfo() async {
    final box = Hive.box(_testimonialInfoBox);
    return _readAllInfoRecords<TestimonialInfo>(box, (id, data) => TestimonialInfo.fromMap(id, data));
  }

  Future<void> clearTestimonialInfo() async {
    final box = Hive.box(_testimonialInfoBox);
    await box.clear();
  }

  Future<void> deleteTestimonialInfoData(final String id) async {
    final box = Hive.box(_testimonialInfoBox);
    await box.delete(id);
  }

  Future<int> readInfoCollectionLastUpdate(final String sectionKey) async {
    final box = Hive.box(_metadataBox);
    final dynamic value = box.get('${sectionKey}_last_update');
    if (value is int) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return 0;
  }

  Future<void> writeInfoCollectionLastUpdate(final String sectionKey, final int value) async {
    final box = Hive.box(_metadataBox);
    await box.put('${sectionKey}_last_update', value);
  }

  Future<bool> haveCheckedInfoCollectionUpdates(final String sectionKey) async {
    final box = Hive.box(_metadataBox);
    final dynamic checkDay = box.get('${sectionKey}_check_date');
    final int today = DateTime.now().day;

    if (checkDay is int && checkDay == today) {
      return true;
    }

    if (checkDay is String && int.tryParse(checkDay) == today) {
      return true;
    }

    await box.put('${sectionKey}_check_date', today);
    return false;
  }

  // * User Profile Images (cross-platform)
  /// Save user profile image bytes to cache
  Future<void> writeUserImage(final String userId, final Uint8List imageBytes) async {
    final key = 'user_$userId';
    await _writeCachedImage(key, imageBytes);
  }

  /// Read user profile image bytes from cache
  Future<Uint8List?> readUserImage(final String userId) async {
    final key = 'user_$userId';
    final box = Hive.box(_imagesCacheBox);
    final dynamic data = box.get(key);
    if (data != null && data is Uint8List) {
      // Update timestamp for LRU
      await _updateAccessTimestamp(key);
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
    final key = 'media_$mediaKey';
    await _writeCachedImage(key, imageBytes);
  }

  /// Read media image bytes from cache
  Future<Uint8List?> readMediaImage(final String mediaKey) async {
    final key = 'media_$mediaKey';
    final box = Hive.box(_imagesCacheBox);
    final dynamic data = box.get(key);
    if (data != null && data is Uint8List) {
      // Update timestamp for LRU
      await _updateAccessTimestamp(key);
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
    final key = 'video_${postId}_$videoKey';
    await _writeCachedImage(key, imageBytes);
  }

  /// Read video thumbnail bytes from cache
  Future<Uint8List?> readVideoThumbnail(final String postId, final String videoKey) async {
    final key = 'video_${postId}_$videoKey';
    final box = Hive.box(_imagesCacheBox);
    final dynamic data = box.get(key);
    if (data != null && data is Uint8List) {
      // Update timestamp for LRU
      await _updateAccessTimestamp(key);
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

  // * Cache Management & LRU Implementation

  /// Internal method to write cached image with quota management
  Future<void> _writeCachedImage(String key, Uint8List imageBytes) async {
    try {
      // Check cache size before writing
      final currentSize = await getCurrentCacheSize();
      final newItemSize = imageBytes.length;

      // If adding this would exceed limit, evict old entries
      if (currentSize + newItemSize > maxCacheSizeBytes) {
        debugPrint(
            'Cache size would exceed limit (${(currentSize + newItemSize) / 1024 / 1024}MB). Evicting old entries...');
        await _evictLeastRecentlyUsed();
      }

      final box = Hive.box(_imagesCacheBox);
      await box.put(key, imageBytes);
      await _updateAccessTimestamp(key);
    } catch (e) {
      // Handle QuotaExceededError on web
      if (e.toString().contains('QuotaExceeded') ||
          e.toString().contains('quota') ||
          e.toString().contains('storage')) {
        debugPrint('Storage quota exceeded! Clearing cache and retrying...');
        await _evictLeastRecentlyUsed(forceEviction: true);

        // Retry once after eviction
        try {
          final box = Hive.box(_imagesCacheBox);
          await box.put(key, imageBytes);
          await _updateAccessTimestamp(key);
        } catch (retryError) {
          debugPrint('Failed to write cache even after eviction: $retryError');
          rethrow;
        }
      } else {
        debugPrint('Error writing cached image: $e');
        rethrow;
      }
    }
  }

  /// Update the access timestamp for LRU tracking
  Future<void> _updateAccessTimestamp(String key) async {
    final timestampsBox = Hive.box(_cacheTimestampsBox);
    await timestampsBox.put(key, DateTime.now().millisecondsSinceEpoch);
  }

  /// Evict least recently used cache entries
  Future<void> _evictLeastRecentlyUsed({bool forceEviction = false}) async {
    final box = Hive.box(_imagesCacheBox);
    final timestampsBox = Hive.box(_cacheTimestampsBox);

    if (box.isEmpty) return;

    // Get all keys with their timestamps
    final Map<String, int> keyTimestamps = {};
    for (final key in box.keys) {
      final timestamp = timestampsBox.get(key);
      if (timestamp != null && timestamp is int) {
        keyTimestamps[key.toString()] = timestamp;
      } else {
        // If no timestamp, consider it very old
        keyTimestamps[key.toString()] = 0;
      }
    }

    // Sort by timestamp (oldest first)
    final sortedKeys = keyTimestamps.keys.toList()..sort((a, b) => keyTimestamps[a]!.compareTo(keyTimestamps[b]!));

    // Calculate how many to remove
    int numToRemove;
    if (forceEviction) {
      // Remove 50% when forced (quota exceeded)
      numToRemove = (sortedKeys.length * 0.5).ceil();
    } else {
      // Remove configured percentage
      numToRemove = (sortedKeys.length * evictionPercentage).ceil();
    }

    numToRemove = numToRemove.clamp(1, sortedKeys.length);

    final keysToRemove = sortedKeys.take(numToRemove).toList();

    debugPrint('Evicting $numToRemove cache entries (${forceEviction ? "forced" : "normal"})');

    // Remove from both boxes
    await box.deleteAll(keysToRemove);
    await timestampsBox.deleteAll(keysToRemove);

    final newSize = await getCurrentCacheSize();
    debugPrint('Cache size after eviction: ${(newSize / 1024 / 1024).toStringAsFixed(2)}MB');
  }

  /// Get current cache size in bytes
  Future<int> getCurrentCacheSize() async {
    final box = Hive.box(_imagesCacheBox);
    int totalSize = 0;

    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null && data is Uint8List) {
        totalSize += data.length;
      }
    }

    return totalSize;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final box = Hive.box(_imagesCacheBox);
    final timestampsBox = Hive.box(_cacheTimestampsBox);

    final totalSize = await getCurrentCacheSize();
    final itemCount = box.length;

    // Count by type
    int userImages = 0;
    int mediaImages = 0;
    int videoThumbnails = 0;

    for (final key in box.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('user_')) {
        userImages++;
      } else if (keyStr.startsWith('media_')) {
        mediaImages++;
      } else if (keyStr.startsWith('video_')) {
        videoThumbnails++;
      }
    }

    return {
      'totalSizeBytes': totalSize,
      'totalSizeMB': totalSize / 1024 / 1024,
      'itemCount': itemCount,
      'userImages': userImages,
      'mediaImages': mediaImages,
      'videoThumbnails': videoThumbnails,
      'maxSizeMB': maxCacheSizeBytes / 1024 / 1024,
      'percentageUsed': (totalSize / maxCacheSizeBytes) * 100,
      'timestampTracking': timestampsBox.length,
    };
  }

  /// Clear all cached images and timestamps
  Future<void> clearImageCache() async {
    final box = Hive.box(_imagesCacheBox);
    final timestampsBox = Hive.box(_cacheTimestampsBox);
    await box.clear();
    await timestampsBox.clear();
    debugPrint('Image cache cleared');
  }

  /// Remove old entries if cache is getting close to limit
  Future<void> performCacheMaintenance() async {
    final currentSize = await getCurrentCacheSize();

    if (currentSize > warningCacheSizeBytes) {
      debugPrint(
          'Cache size approaching limit (${(currentSize / 1024 / 1024).toStringAsFixed(2)}MB). Performing maintenance...');
      await _evictLeastRecentlyUsed();
    }
  }

  List<T> _readAllInfoRecords<T>(
      final Box<dynamic> box, final T Function(String id, Map<String, dynamic> data) fromMap) {
    final List<T> results = <T>[];

    for (final key in box.keys) {
      final dynamic data = box.get(key);
      if (data is Map) {
        try {
          results.add(fromMap(key.toString(), Map<String, dynamic>.from(data)));
        } catch (e) {
          debugPrint('Error deserializing info cache entry $key: $e');
        }
      }
    }

    return results;
  }
}
