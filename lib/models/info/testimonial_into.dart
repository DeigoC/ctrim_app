import 'dart:convert';

class TestimonialInfo {
  final String body, name, church, imgSrc;

  TestimonialInfo(this.name, this.church, this.body, this.imgSrc);

  String encode() {
    Map<String, String> data = {'body': jsonEncode(body), 'name': name, 'church': church, 'imgSrc': imgSrc};

    return jsonEncode(data);
  }
}
