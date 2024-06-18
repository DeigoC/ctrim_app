import 'dart:convert';

class CtrimInfo {
  final String body, church;

  CtrimInfo(this.church, {required this.body});

  // TODO test the encoding of the body below if we can read it well afterwards
  String encode() {
    Map<String, String> data = {'body': jsonEncode(body), 'church': church};

    return jsonEncode(data);
  }
}
