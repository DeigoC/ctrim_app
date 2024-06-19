import 'dart:convert';

class CtrimInfo {
  final String _church;
  final List<dynamic> _body;

  CtrimInfo(final Map<String, dynamic> data)
      : _body = data['body'],
        _church = data['church'];

  String encode() {
    Map<String, dynamic> data = {'body': _body, 'church': _church};

    return jsonEncode(data);
  }

  List<dynamic> get body => _body;
}
