class PostTemplate {
  late String _title, _description, _headTitle, _body;

  PostTemplate({required final String title, required String description, required String headTitle}) {
    _title = title;
    _description = description;
    _headTitle = headTitle;
    _body = "TODO: get that default text";
  }

  String get title => _title;
  String get description => _description;
  String get headTitle => _headTitle;
  String get body => _body;

  void setTitle(final String title) => _title = title;
  void setDescription(final String description) => _description = description;
  void setHeadTitle(final String headTitle) => _headTitle = headTitle;
  void setBody(final String body) => _body = body;
}
