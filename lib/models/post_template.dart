class PostTemplate {
  late String _id, _title, _description, _headTitle, _body;

  PostTemplate(
      {required String id, required final String title, required String description, required String headTitle}) {
    _id = id;
    _title = title;
    _description = description;
    _headTitle = headTitle;
    _body = "TODO: get that default text";
  }

  PostTemplate.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _title = data['Title'],
        _description = data['Description'],
        _headTitle = data['HeadTitle'],
        _body = data['Body'];

  toJson() {
    return {'Title': _title, 'Description': _description, 'HeadTitle': _headTitle, 'Body': _body};
  }

  String get id => _id;
  String get title => _title;
  String get description => _description;
  String get headTitle => _headTitle;
  String get body => _body;

  void setTitle(final String title) => _title = title;
  void setDescription(final String description) => _description = description;
  void setHeadTitle(final String headTitle) => _headTitle = headTitle;
  void setBody(final String body) => _body = body;

  // TODO we need a special method that converts all the fields to a json format to be stored locally
  // TODO likewise, we need to create a special constructor that builds from a json/map
}
