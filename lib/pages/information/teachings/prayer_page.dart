import 'dart:convert';

import 'package:provider/provider.dart';

import '../../../utility/app_context.dart';
import '../../../widgets/info/info_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class PrayerPage extends StatelessWidget {
  const PrayerPage({super.key});

  static const String _json = r"""
[{"insert":"Prayers"},{"insert":"\n","attributes":{"header":1}},{"insert":"Prayers are crucial to Christians for various reasons, as emphasized throughout the Bible. Here are some references and explanations highlighting the importance of prayers:\n\n1. Communication with God"},{"insert":"\n","attributes":{"header":2}},{"insert":"But Jesus often withdrew to lonely places and prayer"},{"insert":"\n","attributes":{"blockquote":true}},{"insert":"-"},{"insert":"Luke 5:16","attributes":{"italic":true}},{"insert":"\n","attributes":{"blockquote":true}},{"insert":"\nVery early in the morning, while it was still dark, Jesus got up, left the house and went off to a solitary place, where he prayed."},{"insert":"\n","attributes":{"blockquote":true}},{"insert":"-"},{"insert":"Mark 1:35","attributes":{"italic":true}},{"insert":"\n","attributes":{"blockquote":true}},{"insert":"\nPrayer is the primary means of communication between Christians and God. In the New Testament, Jesus Himself set an example by frequently praying to His Heavenly Father (Luke 5:16, Mark 1:35). It allows Christians to talk to God, share their thoughts, concerns, and feelings, and seek guidance.\n\n2. Strengthening Faith"},{"insert":"\n","attributes":{"header":2}},{"insert":"Praying reinforces a Christian's faith. In the book of James, it states that when believers pray with faith, God responds (James 5:15). Through prayer, Christians express their trust in God's power and provision, which deepens their relationship with Him.\n\n3. Seeking Guidance and Wisdom"},{"insert":"\n","attributes":{"header":2}},{"insert":"Proverbs 3:5-6 encourages believers to trust in the Lord and lean not on their understanding. Prayer enables Christians to seek God's wisdom and understanding when faced with difficult decisions or uncertainties.\n\n4.  Finding Comfort and Peace"},{"insert":"\n","attributes":{"header":2}},{"insert":"In times of trouble or distress, Christians can find solace through prayer. Philippians 4:6-7 teaches that through prayer, Christians can experience the peace of God that transcends all understanding, guarding their hearts and minds.\n\n5. Confession and Forgiveness"},{"insert":"\n","attributes":{"header":2}},{"insert":"Prayer provides an avenue for believers to confess their sins to God, seeking forgiveness and cleansing. In 1 John 1:9, it says, \"If we confess our sins, he is faithful and just to forgive us our sins and to cleanse us from all unrighteousness.\"\n\n6. Expressing Gratitude"},{"insert":"\n","attributes":{"header":2}},{"insert":"Christians are encouraged to offer prayers of thanksgiving and praise to God. 1 Thessalonians 5:16-18 urges believers to \"Rejoice always, pray without ceasing, give thanks in all circumstances; for this is the will of God in Christ Jesus for you.\"\n\n7. Interceding for Others"},{"insert":"\n","attributes":{"header":2}},{"insert":"The Bible encourages Christians to pray not only for themselves but also for others. In 1 Timothy 2:1, Paul urges believers to pray for all people, including leaders and those in authority.\n\n8. Spiritual Growth"},{"insert":"\n","attributes":{"header":2}},{"insert":"Prayer plays a vital role in the spiritual growth and transformation of Christians. As they spend time in communion with God, they become more attuned to His will and develop a deeper understanding of His Word.\n\nConclusion"},{"insert":"\n","attributes":{"header":2}},{"insert":"Overall, the Bible portrays prayer as an essential aspect of a Christian's life, a way to draw closer to God, seek His guidance, and experience His love, mercy, and power. Through prayer, Christians can find strength, comfort, and a deeper connection with their Creator, shaping their faith and relationship with Him.\n"}]""";

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.setCurrentScreen(screenName: 'Topic: Family');
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
