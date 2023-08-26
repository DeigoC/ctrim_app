import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../../utility/app_context.dart';
import '../../../widgets/info/info_appbar.dart';

class BibleReadingPage extends StatelessWidget {
  const BibleReadingPage({super.key});
  static const String _json = r"""
[{"insert":"Reading the Bible"},{"insert":"\n","attributes":{"header":1}},{"insert":"\nReading the Bible is of paramount importance to Christians, and numerous references in the Bible itself emphasize its significance. Here are some of the reasons why reading the Bible is crucial for Christians:\n\n1. God's Word"},{"insert":"\n","attributes":{"header":2}},{"insert":"The Bible is considered the Word of God by Christians. It is divinely inspired and serves as the ultimate authority for faith and life (2 Timothy 3:16-17). Reading the Bible enables Christians to understand God's teachings, will, and character.\n\n2. Spiritual Nourishment"},{"insert":"\n","attributes":{"header":2}},{"insert":"Just as physical food nourishes the body, the Bible provides spiritual nourishment to believers. In Matthew 4:4, Jesus quotes Deuteronomy, saying, \"Man shall not live by bread alone, but by every word that comes from the mouth of God.\" Regular reading of the Bible helps Christians grow spiritually and mature in their faith.\n\n3. Revelation of God's Plan"},{"insert":"\n","attributes":{"header":2}},{"insert":"The Bible reveals God's redemptive plan for humanity through the life, death, and resurrection of Jesus Christ. It presents the story of salvation, showcasing God's love and mercy towards humanity.\n\n4. Transformation"},{"insert":"\n","attributes":{"header":2}},{"insert":"The Bible has the power to transform lives. Romans 12:2 encourages believers not to conform to the patterns of the world but to be transformed by the renewing of their minds through the Scriptures.\n\n5. Guidance and Wisdom"},{"insert":"\n","attributes":{"header":2}},{"insert":"Psalm 119:105 states, \"Your word is a lamp to my feet and a light to my path.\" Reading the Bible provides Christians with guidance and wisdom to navigate the complexities of life.\n\n6. Strengthening Faith"},{"insert":"\n","attributes":{"header":2}},{"insert":"Reading the accounts of God's faithfulness and the testimonies of His people throughout the Bible strengthens the faith of believers. Romans 10:17 affirms that \"faith comes from hearing, and hearing through the word of Christ.\"\n\n7. Resistance to Temptation"},{"insert":"\n","attributes":{"header":2}},{"insert":"When faced with temptations, Jesus responded with the Scriptures during His temptations in the wilderness (Matthew 4:1-11). Likewise, Christians can draw on the truths of the Bible to resist temptation and stand firm in their faith.\n\n8. Communion with God"},{"insert":"\n","attributes":{"header":2}},{"insert":"Through the Scriptures, Christians can encounter God's presence and commune with Him. The Bible acts as a bridge between humans and God, allowing believers to know Him intimately.\n\n9. Equipping for Service"},{"insert":"\n","attributes":{"header":2}},{"insert":"2 Timothy 3:16-17 teaches that the Scriptures equip believers for every good work. By reading the Bible, Christians are equipped to serve others and share the message of God's love and salvation.\n\n10. Unity and Fellowship"},{"insert":"\n","attributes":{"header":2}},{"insert":"As believers read and study the Bible together, it fosters unity and fellowship within the Christian community. Shared understanding of God's Word strengthens relationships among believers.\n\nConclusion"},{"insert":"\n","attributes":{"header":2}},{"insert":"In summary, reading the Bible is foundational to a Christian's faith journey. It is essential for spiritual growth, discernment, and developing a deeper relationship with God. Through the Scriptures, Christians gain insight into God's character, His plan for humanity, and the transformative power of His Word in their lives.\n"}]""";

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.setCurrentScreen(screenName: 'Topic: Bible Reading');
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
