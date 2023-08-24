import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../widgets/info/info_appbar.dart';

class LovePage extends StatelessWidget {
  const LovePage({super.key});

  static const String _json = r"""
[{"insert":"Love"},{"insert":"\n","attributes":{"header":1}},{"insert":"\nThe topic of love is central to Christianity, and the Bible contains numerous references that emphasize its significance in the life of a Christian. Here are some reasons why love is crucial for Christians:\n\n1. God's Love"},{"insert":"\n","attributes":{"header":2}},{"insert":"The Bible repeatedly speaks of God's love for humanity. One of the most well-known verses is John 3:16, which states, \"For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.\" God's love is the foundation of Christian faith, and it serves as an example for believers to follow.\n\n2. Command to Love"},{"insert":"\n","attributes":{"header":2}},{"insert":"Jesus emphasized the importance of love in the New Testament. In Matthew 22:37-39, He summarized the greatest commandments, saying, \"Love the Lord your God with all your heart and with all your soul and with all your mind. This is the first and greatest commandment. And the second is like it: 'Love your neighbor as yourself.'\" Christians are called to love both God and their fellow human beings.\n\n3. Love as a Fruit of the Spirit"},{"insert":"\n","attributes":{"header":2}},{"insert":"In Galatians 5:22-23, love is listed as one of the fruits of the Holy Spirit. This implies that love should naturally manifest in the lives of believers who are filled with the Spirit.\n\n4. Unity and Fellowship"},{"insert":"\n","attributes":{"header":2}},{"insert":"Love fosters unity and fellowship among Christians. In 1 Peter 4:8, it says, \"Above all, love each other deeply because love covers over a multitude of sins.\" Love enables believers to support and care for one another, creating a strong and supportive community.\n\n5. Love for Enemies"},{"insert":"\n","attributes":{"header":2}},{"insert":"Jesus challenged His followers to love even their enemies (Matthew 5:44). This radical form of love demonstrates the transformative power of Christ's teachings and showcases God's love to the world.\n\n6. Love in Action"},{"insert":"\n","attributes":{"header":2}},{"insert":"The Bible stresses the importance of not merely professing love but demonstrating it through actions. 1 John 3:18 urges believers to love not with words or speech but with actions and truth.\n\n7. Selfless Love"},{"insert":"\n","attributes":{"header":2}},{"insert":"Christians are encouraged to love selflessly, as Christ loved them. In John 15:13, Jesus said, \"Greater love has no one than this: to lay down one's life for one's friends.\" Following Jesus' example, believers are called to sacrificially love others.\n\n8. Love and Forgiveness"},{"insert":"\n","attributes":{"header":2}},{"insert":"Love is intrinsically linked to forgiveness. Colossians 3:13 emphasizes that Christians should forgive others as the Lord forgave them, promoting reconciliation and healing.\n\n9. Love in Marriage and Relationships"},{"insert":"\n","attributes":{"header":2}},{"insert":"The Bible provides guidance on love within the context of marriage and relationships. Ephesians 5:25 instructs husbands to love their wives as Christ loved the church, setting an example of sacrificial and caring love.\n\n10. Love as a Witness"},{"insert":"\n","attributes":{"header":2}},{"insert":"Jesus said that people will recognize His followers by their love for one another (John 13:35). Love serves as a powerful witness to the world, drawing others to the message of Christ's love and salvation.\n\nConclusion"},{"insert":"\n","attributes":{"header":2}},{"insert":"Love is a fundamental aspect of Christianity, reflecting God's character and commandments. It is a transformative force that unites believers, empowers them to serve others, and serves as a powerful testimony of God's love to the world.\n"}]""";

  @override
  Widget build(BuildContext context) {
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(jsonDecode(_json)), selection: const TextSelection.collapsed(offset: 0));
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 8;

    return Scaffold(
        body: CustomScrollView(slivers: [
      const SliverAppBar(actions: [InfoAction(json: _json)], floating: true, snap: true),
      SliverToBoxAdapter(
          child: SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: webHorizontalPadding),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: quill.QuillEditor.basic(controller: controller, readOnly: true)),
                    const SizedBox(height: 32)
                  ]))))
    ]));
  }
}
