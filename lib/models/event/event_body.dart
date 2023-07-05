import 'dart:convert';

class EventBody {
  String _json = '[{"insert":"Hello, time to start writing!\n"}]';
  String get json => _json;
  List<dynamic> get decodedJson => jsonDecode(_json.replaceAll('\n', '\\n'));
  void encodeJson(List<dynamic> json) => _json = jsonEncode(json);
  void setJson(String json) => _json = json;
}
