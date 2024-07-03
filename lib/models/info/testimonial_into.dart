import 'dart:convert';

class TestimonialInfo {
  final String _name, _church, _imgSrc;
  final List<dynamic> _body;

  TestimonialInfo(final Map<String, dynamic> data)
      : _body = data['body'],
        _name = data['name'],
        _church = data['church'],
        _imgSrc = data['imgSrc'];

  String encode() {
    Map<String, dynamic> data = {'body': body, 'name': _name, 'church': _church, 'imgSrc': _imgSrc};

    return jsonEncode(data);
  }

  List<dynamic> get body => _body;
  String get church => _church;
  String get name => _name;
}
