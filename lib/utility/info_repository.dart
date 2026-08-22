import '../firebase/db_managers/info_db_manager.dart';
import '../models/info/church_info.dart';
import '../models/info/church_page.dart';
import '../models/info/ctrim_info.dart';
import '../models/info/testimonial_info.dart';
import 'local_data_manager.dart';

class InfoRepository {
  InfoRepository({
    LocalDataManager? localDataManager,
    ChurchInfoDBManager? churchInfoDBManager,
    TestimonialInfoDBManager? testimonialInfoDBManager,
    CtrimInfoDBManager? ctrimInfoDBManager,
    ChurchPageDBManager? churchPageDBManager,
  })  : _localDataManager = localDataManager ?? LocalDataManager(),
        _churchInfoDBManager = churchInfoDBManager ?? ChurchInfoDBManager(),
        _testimonialInfoDBManager =
            testimonialInfoDBManager ?? TestimonialInfoDBManager(),
        _ctrimInfoDBManager = ctrimInfoDBManager ?? CtrimInfoDBManager(),
        _churchPageDBManager = churchPageDBManager ?? ChurchPageDBManager();

  static const String churchesSection = 'churches';
  static const String testimonialsSection = 'testimonials';
  static const String ctrimInfoSection = 'ctrim_info';

  final LocalDataManager _localDataManager;
  final ChurchInfoDBManager _churchInfoDBManager;
  final TestimonialInfoDBManager _testimonialInfoDBManager;
  final CtrimInfoDBManager _ctrimInfoDBManager;
  final ChurchPageDBManager _churchPageDBManager;

  Future<List<ChurchInfo>> fetchChurches({bool forceRefresh = false}) async {
    return _loadCollection<ChurchInfo>(
      sectionKey: churchesSection,
      forceRefresh: forceRefresh,
      fetchRemote: _churchInfoDBManager.fetchAll,
      readLocal: _localDataManager.readAllChurchInfo,
      writeLocal: (records) async {
        await _localDataManager.clearChurchInfo();
        for (final record in records) {
          await _localDataManager.writeChurchInfoData(record);
        }
      },
      fetchRemoteLastUpdate: _churchInfoDBManager.fetchLastUpdate,
      sortRecords: (records) => _sortByDisplayOrder(
          records, (record) => record.displayOrder, (record) => record.title),
    );
  }

  Future<ChurchInfo?> fetchChurchById(final String id,
      {bool forceRefresh = false}) async {
    final records = await fetchChurches(forceRefresh: forceRefresh);
    return _firstWhereOrNull<ChurchInfo>(records, (record) => record.id == id);
  }

  Future<void> saveChurchInfo(final ChurchInfo info) async {
    await _churchInfoDBManager.save(info.id, info);
    await _localDataManager.writeChurchInfoData(info);
    await _localDataManager.writeInfoCollectionLastUpdate(
      churchesSection,
      info.updatedAt.millisecondsSinceEpoch,
    );
  }

  Future<void> deleteChurchInfo(final String id) async {
    await _churchPageDBManager.deleteAll(id);
    await _localDataManager.clearChurchPages(id);
    await _churchInfoDBManager.delete(id);
    await _localDataManager.deleteChurchInfoData(id);
    final lastUpdate = await _churchInfoDBManager.fetchLastUpdate();
    await _localDataManager.writeInfoCollectionLastUpdate(
        churchesSection, lastUpdate);
  }

  Future<List<ChurchPage>> fetchChurchPages(
    final String churchId, {
    bool forceRefresh = false,
  }) async {
    return _loadCollection<ChurchPage>(
      sectionKey: LocalDataManager.churchPagesSectionKey(churchId),
      forceRefresh: forceRefresh,
      fetchRemote: () => _churchPageDBManager.fetchAll(churchId),
      readLocal: () => _localDataManager.readChurchPages(churchId),
      writeLocal: (records) async {
        await _localDataManager.clearChurchPages(churchId);
        for (final record in records) {
          await _localDataManager.writeChurchPageData(record);
        }
      },
      fetchRemoteLastUpdate: () =>
          _churchPageDBManager.fetchLastUpdate(churchId),
      sortRecords: (records) => _sortByDisplayOrder(
          records, (record) => record.displayOrder, (record) => record.title),
    );
  }

  Future<ChurchPage?> fetchChurchPageById(
    final String churchId,
    final String id, {
    bool forceRefresh = false,
  }) async {
    final records =
        await fetchChurchPages(churchId, forceRefresh: forceRefresh);
    return _firstWhereOrNull<ChurchPage>(records, (record) => record.id == id);
  }

  Future<void> saveChurchPage(final ChurchPage page) async {
    await _churchPageDBManager.save(page.churchId, page.id, page);
    await _localDataManager.writeChurchPageData(page);
    await _localDataManager.writeInfoCollectionLastUpdate(
      LocalDataManager.churchPagesSectionKey(page.churchId),
      page.updatedAt.millisecondsSinceEpoch,
    );
  }

  Future<void> deleteChurchPage(final String churchId, final String id) async {
    await _churchPageDBManager.delete(churchId, id);
    await _localDataManager.deleteChurchPageData(churchId, id);
    final lastUpdate = await _churchPageDBManager.fetchLastUpdate(churchId);
    await _localDataManager.writeInfoCollectionLastUpdate(
      LocalDataManager.churchPagesSectionKey(churchId),
      lastUpdate,
    );
  }

  Future<List<TestimonialInfo>> fetchTestimonials(
      {bool forceRefresh = false}) async {
    return _loadCollection<TestimonialInfo>(
      sectionKey: testimonialsSection,
      forceRefresh: forceRefresh,
      fetchRemote: _testimonialInfoDBManager.fetchAll,
      readLocal: _localDataManager.readAllTestimonialInfo,
      writeLocal: (records) async {
        await _localDataManager.clearTestimonialInfo();
        for (final record in records) {
          await _localDataManager.writeTestimonialInfoData(record);
        }
      },
      fetchRemoteLastUpdate: _testimonialInfoDBManager.fetchLastUpdate,
      sortRecords: (records) => _sortByDisplayOrder(
          records, (record) => record.displayOrder, (record) => record.name),
    );
  }

  Future<TestimonialInfo?> fetchTestimonialById(final String id,
      {bool forceRefresh = false}) async {
    final records = await fetchTestimonials(forceRefresh: forceRefresh);
    return _firstWhereOrNull<TestimonialInfo>(
        records, (record) => record.id == id);
  }

  Future<void> saveTestimonialInfo(final TestimonialInfo info) async {
    await _testimonialInfoDBManager.save(info.id, info);
    await _localDataManager.writeTestimonialInfoData(info);
    await _localDataManager.writeInfoCollectionLastUpdate(
      testimonialsSection,
      info.updatedAt.millisecondsSinceEpoch,
    );
  }

  Future<void> deleteTestimonialInfo(final String id) async {
    await _testimonialInfoDBManager.delete(id);
    await _localDataManager.deleteTestimonialInfoData(id);
    final lastUpdate = await _testimonialInfoDBManager.fetchLastUpdate();
    await _localDataManager.writeInfoCollectionLastUpdate(
        testimonialsSection, lastUpdate);
  }

  Future<List<CtrimInfo>> fetchCtrimInfo({bool forceRefresh = false}) async {
    return _loadCollection<CtrimInfo>(
      sectionKey: ctrimInfoSection,
      forceRefresh: forceRefresh,
      fetchRemote: _ctrimInfoDBManager.fetchAll,
      readLocal: _localDataManager.readAllCtrimInfo,
      writeLocal: (records) async {
        await _localDataManager.clearCtrimInfo();
        for (final record in records) {
          await _localDataManager.writeCtrimInfoData(record);
        }
      },
      fetchRemoteLastUpdate: _ctrimInfoDBManager.fetchLastUpdate,
      sortRecords: (records) => _sortByDisplayOrder(
          records, (record) => record.displayOrder, (record) => record.title),
    );
  }

  Future<CtrimInfo?> fetchCtrimInfoById(final String id,
      {bool forceRefresh = false}) async {
    final records = await fetchCtrimInfo(forceRefresh: forceRefresh);
    return _firstWhereOrNull<CtrimInfo>(records, (record) => record.id == id);
  }

  Future<void> saveCtrimInfo(final CtrimInfo info) async {
    await _ctrimInfoDBManager.save(info.id, info);
    await _localDataManager.writeCtrimInfoData(info);
    await _localDataManager.writeInfoCollectionLastUpdate(
      ctrimInfoSection,
      info.updatedAt.millisecondsSinceEpoch,
    );
  }

  Future<void> deleteCtrimInfo(final String id) async {
    await _ctrimInfoDBManager.delete(id);
    await _localDataManager.deleteCtrimInfoData(id);
    final lastUpdate = await _ctrimInfoDBManager.fetchLastUpdate();
    await _localDataManager.writeInfoCollectionLastUpdate(
        ctrimInfoSection, lastUpdate);
  }

  Future<List<T>> _loadCollection<T>({
    required String sectionKey,
    required bool forceRefresh,
    required Future<List<T>> Function() fetchRemote,
    required Future<List<T>> Function() readLocal,
    required Future<void> Function(List<T> records) writeLocal,
    required Future<int> Function() fetchRemoteLastUpdate,
    required List<T> Function(List<T>) sortRecords,
  }) async {
    final List<T> cachedRecords = await readLocal();

    int remoteLastUpdate;
    try {
      remoteLastUpdate = await fetchRemoteLastUpdate();
    } catch (_) {
      if (cachedRecords.isNotEmpty) {
        return sortRecords(cachedRecords);
      }
      rethrow;
    }

    final int localLastUpdate =
        await _localDataManager.readInfoCollectionLastUpdate(sectionKey);

    if (!forceRefresh &&
        cachedRecords.isNotEmpty &&
        remoteLastUpdate == localLastUpdate) {
      return sortRecords(cachedRecords);
    }

    final List<T> remoteRecords;
    try {
      remoteRecords = await fetchRemote();
    } catch (_) {
      if (cachedRecords.isNotEmpty) {
        return sortRecords(cachedRecords);
      }
      rethrow;
    }
    await writeLocal(remoteRecords);
    await _localDataManager.writeInfoCollectionLastUpdate(
        sectionKey, remoteLastUpdate);
    return sortRecords(remoteRecords);
  }

  List<T> _sortByDisplayOrder<T>(
    final List<T> records,
    final int Function(T record) displayOrder,
    final String Function(T record) secondaryLabel,
  ) {
    final List<T> sorted = List<T>.from(records);
    sorted.sort((a, b) {
      final int orderCompare = displayOrder(a).compareTo(displayOrder(b));
      if (orderCompare != 0) {
        return orderCompare;
      }
      return secondaryLabel(a)
          .toLowerCase()
          .compareTo(secondaryLabel(b).toLowerCase());
    });
    return sorted;
  }

  T? _firstWhereOrNull<T>(
      final List<T> records, final bool Function(T record) test) {
    for (final record in records) {
      if (test(record)) {
        return record;
      }
    }
    return null;
  }
}
