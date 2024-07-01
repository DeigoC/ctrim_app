import 'dart:convert';

class EventBody {
  String _json = r'[{"insert":"Hello, time to start writing!\n"}]';
  String get json => _json;
  List<dynamic> get decodedJson => jsonDecode(_json.replaceAll('\n', '\\n'));

  void encodeJson(final List<dynamic> json) => _json = jsonEncode(json);

  void setJson(final String json) => _json = json;

  int compareTo(final List<dynamic> otherJson) {
    return jsonEncode(otherJson).compareTo(_json);
  }
}
