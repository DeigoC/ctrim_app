import 'dart:convert';

class CtrimInfo {
  final String _imgSrc, _analyticsTitle;
  final List<dynamic> _body;

  CtrimInfo(final Map<String, dynamic> data)
      : _body = data['body'],
        _imgSrc = data['imgSrc'],
        _analyticsTitle = data['analyticTitle'];

  String encode() {
    Map<String, dynamic> data = {'body': _body, 'imgSrc': _imgSrc};

    return jsonEncode(data);
  }

  List<dynamic> get body => _body;
  String get analyticsTitle => _analyticsTitle;
}
