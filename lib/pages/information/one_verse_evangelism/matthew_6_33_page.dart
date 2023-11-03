import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class Matthew633Page extends StatelessWidget {
  const Matthew633Page({super.key});
  static const String _json = r"""
[{"insert":" Seeking God's Kingdom"},{"insert":"\n","attributes":{"align":"center","header":1}},{"insert":"But seek first the kingdom of God and his righteousness, and all these things will be added to you."},{"insert":"\n","attributes":{"align":"center","blockquote":true}},{"insert":"Matthew 6:33"},{"insert":"\n","attributes":{"align":"right"}},{"insert":"\nIn this simple yet profound verse, Jesus imparts a timeless lesson that holds the key to a purposeful and fulfilled life. As we explore these words, let us uncover three essential principles that can guide us on our journey of faith:\n\n1. Priority of God's Kingdom"},{"insert":"\n","attributes":{"header":2}},{"insert":"The heart of Jesus' message in Matthew 6:33 lies in the command to \"seek first the kingdom of God.\" This directive speaks to the importance of aligning our priorities with God's eternal purposes. It's easy to become consumed by the cares of this world – our material needs, ambitions, and desires. However, Jesus urges us to place the pursuit of His kingdom above all else.\n\nWhen we seek God's kingdom first, we acknowledge that our ultimate allegiance is to Him. We recognize that His reign and rule should shape every aspect of our lives. This means seeking His will in our decisions, relationships, and actions. Just as a sailor steers a ship toward its destination, seeking God's kingdom guides us toward a life of significance and impact.\n\n2. Pursuit of Righteousness"},{"insert":"\n","attributes":{"header":2}},{"insert":"Jesus continues by instructing us to seek not only His kingdom but also \"his righteousness.\" Righteousness refers to living in accordance with God's moral and ethical standards. It's about reflecting His character in our thoughts, words, and deeds. When we prioritize righteousness, we make choices that honor God and promote justice, kindness, and compassion.\n\nThis pursuit of righteousness transforms us from the inside out. It reshapes our attitudes, motivations, and behavior. As we seek to live righteously, we become beacons of light in a world often clouded by darkness. Just as a lamp illuminates a room, our righteous living shines a light that draws others closer to God's truth and love.\n\n3. God's Provision and Care"},{"insert":"\n","attributes":{"header":2}},{"insert":"Jesus assures us that when we seek His kingdom and righteousness, \"all these things will be added to you.\" This promise underscores God's unwavering love and care for His children. He knows our needs – our physical, emotional, and spiritual needs. When we place Him first, He takes upon Himself the responsibility of providing for us.\n\nHowever, it's crucial to understand that seeking God's kingdom is not a formula for instant material gain. Instead, it's a call to trust in His timing and sovereignty. Sometimes, God's provision may come in unexpected ways, challenging us to rely on His wisdom rather than our own understanding. Just as a loving parent provides for their children, our heavenly Father cares for us with immeasurable love and wisdom.\n\nConclusion"},{"insert":"\n","attributes":{"header":2}},{"insert":"In conclusion, Matthew 6:33 encapsulates a life-transforming principle: Seek first the kingdom of God and His righteousness. By prioritizing God's purposes, living righteously, and trusting in His provision, we embark on a journey of purpose and fulfillment. As we navigate the complexities of life, may we remember these words of Jesus and allow them to guide our every step.\n"}]""";

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.setCurrentScreen(screenName: 'Verse: Matthew 6:33');
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(jsonDecode(_json)), selection: const TextSelection.collapsed(offset: 0));
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 8;
    return Scaffold(
        body: CustomScrollView(slivers: [
// const SliverAppBar(actions: [InfoAction(json: _json)], floating: true, snap: true),
      const SliverAppBar(floating: true, snap: true),
      SliverToBoxAdapter(
          child: SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: webHorizontalPadding),
                  child: quill.QuillProvider(
                    configurations: quill.QuillConfigurations(controller: controller),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                          child: quill.QuillEditor.basic(
                              configurations: const quill.QuillEditorConfigurations(readOnly: true))),
                      const SizedBox(height: 32)
                    ]),
                  ))))
    ]));
  }
}
