class ChurchInfo {
  final String _imgSrc, _analyticsTitle;
  final List<dynamic> _body;

  ChurchInfo(final Map<String, dynamic> data)
      : _body = data['body'],
        _imgSrc = data['imgSrc'],
        _analyticsTitle = data['analyticTitle'];

  List<dynamic> get body => _body;
  String get analyticsTitle => _analyticsTitle;
  String get imgSrc => _imgSrc;
}
