import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalDataManager {
  Future<File> _getPostFile(String id) async {
    final path = await _localPath;
    return File('$path/posts/$id.txt');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
