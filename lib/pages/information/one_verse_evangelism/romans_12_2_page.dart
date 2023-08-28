import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class Romans122Page extends StatelessWidget {
  const Romans122Page({super.key});
  static const String _json = r"""
[{"insert":"Transformed by Renewing"},{"insert":"\n","attributes":{"header":1,"align":"center"}},{"insert":"\nDo not be conformed to this world, but be transformed by the renewal of your mind, that by testing you may discern what is the will of God, what is good and acceptable and perfect."},{"insert":"\n","attributes":{"align":"center","blockquote":true}},{"insert":"Romans 12:2"},{"insert":"\n","attributes":{"align":"right"}},{"insert":"\nIn this verse, apostle Paul presents us with a call to radical transformation – a transformation that begins within the mind and ripples outward to impact every facet of our lives. As we reflect on these words, let us uncover three vital lessons that guide us toward a life of renewed thinking and purpose:\n\n1. Rejecting Conformity to the World"},{"insert":"\n","attributes":{"header":2}},{"insert":"Paul's first exhortation is clear: \"Do not be conformed to this world.\" The world often pressures us to adopt its values, desires, and patterns of thinking. Yet, as followers of Christ, we are called to resist this gravitational pull toward conformity. We are called to stand out as lights in the darkness, reflecting the truth and love of our Savior.\n\nConformity to the world can lead us astray from God's path, blurring the lines between right and wrong, truth and deception. But by embracing a counter-cultural mindset grounded in God's Word, we are empowered to navigate life's challenges with discernment and integrity. Just as a lighthouse guides ships away from dangerous shores, our transformed thinking guides us away from worldly pitfalls.\n\n2. Embracing Transformation through Renewal"},{"insert":"\n","attributes":{"header":2}},{"insert":"Paul then provides the solution: \"Be transformed by the renewal of your mind.\" Transformation begins with the renewing of our minds. This process involves a deliberate shift in our thought patterns, values, and perspectives. Instead of being influenced by the world's standards, we align our thinking with God's truth and wisdom.\n\nRenewal takes time and effort. It's a lifelong journey of growth and discovery. As we immerse ourselves in Scripture, prayer, and fellowship with other believers, our minds become attuned to God's heart. Just as a garden flourishes with regular care and attention, our minds flourish when nurtured by God's Word and Spirit.\n\n3. Discerning God's Will"},{"insert":"\n","attributes":{"header":2}},{"insert":"Paul concludes by revealing the purpose of this transformation: \"That by testing you may discern what is the will of God, what is good and acceptable and perfect.\" Renewed minds enable us to discern God's will more clearly. We become sensitive to His leading, understanding what aligns with His character and purposes.\n\nThe world bombards us with conflicting messages, but a transformed mind filters out the noise and focuses on God's truth. Through this discernment, we can make choices that honor God and reflect His goodness. Just as a skilled craftsman identifies the perfect material for a masterpiece, our renewed minds help us discern what is good, acceptable, and perfect in God's eyes.\n\nConclusion"},{"insert":"\n","attributes":{"header":2}},{"insert":"In conclusion, Romans 12:2 invites us into a journey of transformation that begins within our minds. As we reject conformity to the world, embrace renewal, and seek to discern God's will, we step into a life of purpose and meaning. Let us continually yield our minds to the transforming power of God's Word, allowing it to shape us into the image of Christ. Through this process, we become beacons of light and agents of transformation in a world in need of God's love.\n"}]""";

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.setCurrentScreen(screenName: 'Verse: Romans 12:2');
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
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: quill.QuillEditor.basic(controller: controller, readOnly: true, autoFocus: false)),
                    const SizedBox(height: 32)
                  ]))))
    ]));
  }
}
