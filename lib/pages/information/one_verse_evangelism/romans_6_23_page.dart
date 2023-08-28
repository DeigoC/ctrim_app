import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class Romans623Page extends StatelessWidget {
  const Romans623Page({super.key});
  static const String _json = r"""
[{"insert":"Romans 6:23"},{"insert":"\n","attributes":{"header":1,"align":"center"}},{"insert":"For the wages of sin is death, but the gift of God is eternal life in Christ Jesus our Lord"},{"insert":"\n","attributes":{"align":"center","blockquote":true}},{"insert":"\nWages"},{"insert":"\n","attributes":{"header":2}},{"insert":"How would you define the term wages? "},{"insert":"It is something that you earn or deserve","attributes":{"color":"#FFE53935"}},{"insert":". How would you feel if your boss refused to pay you the wages that were due to your? Deep down, we all know that it is only right that a person gets what they deserve. We earn wages from God for how we have lived our lives.\n\nSin"},{"insert":"\n","attributes":{"header":2}},{"insert":"What comes to your mind when you hear the word sin? How would a person have to live in order to get into heaven? "},{"insert":"Sin is more of an attitude than an action - it can be hostile or apathetic response to God.","attributes":{"color":"#FFE53935"}},{"insert":" At any point in your life, has God seemed far away? Our sin creates a distance between us and God.\n\nDeath"},{"insert":"\n","attributes":{"header":2}},{"insert":"What thoughts comes to your mind when you think of death? "},{"insert":"Death actually means separation.","attributes":{"color":"#FFE53935"}},{"insert":" When we die, our soul is separated from our body. If a person chooses to reject God while he is alive, that separation will ultimately result in eternal tournament in hell. Not only will he experience separation from God today, but also forever.\n\nBut"},{"insert":"\n","attributes":{"header":2}},{"insert":"This is the most important word in the verse because it indicates that there is hope for all of us. What we have talked about so far is bad news, but God has good news. What we’re going to talk about now is a contrast to what we have discussed.\n\nGift"},{"insert":"\n","attributes":{"header":2}},{"insert":"What is the difference between a gift and wages? "},{"insert":"A gift is giving out of love to someone, not because of what they do.","attributes":{"color":"#FFE53935"}},{"insert":" How do you feel toward someone who gives you an expensive gift? Some people try to earn God’s favor by doing good deeds, living moral lives or taking part to religious activities. But it is impossible to earn something that has already been bought.\n\nGod"},{"insert":"\n","attributes":{"header":2}},{"insert":"God is the giver of the gift","attributes":{"color":"#FFE53935"}},{"insert":". I can’t give it to you; a church can’t give it to you; no one can give you this gift but God alone. Why do you think God would want to give you a gift? Why does anyone want to give someone a precious gift?\n\nEternal Life"},{"insert":"\n","attributes":{"header":2}},{"insert":"What do you think eternal life is? "},{"insert":"Eternal life would be experiencing life forever with God.","attributes":{"color":"#FFE53935"}},{"insert":" Life is community with God. Just as separation from God starts in this life and extends into eternity, external life starts now and goes on forever. No sin can end it.\n\nJesus Christ"},{"insert":"\n","attributes":{"header":2}},{"insert":"Jesus is the means by which we can obtain the gift of eternal life. "},{"insert":"The one and only Son of God.","attributes":{"color":"#FFE53935"}},{"insert":" No one can offer the gift except the one who purchased it. He purchased it by paying for it with His life.\n\nLord"},{"insert":"\n","attributes":{"header":2}},{"insert":"The gift is offer to everyone who makes Jesus Lord. "},{"insert":"For Jesus to be Lord, He has to have the total control of a person’s life.","attributes":{"color":"#FFE53935"}},{"insert":"\n\nConfession and Surrender"},{"insert":"\n","attributes":{"header":2}},{"insert":"Confessing","attributes":{"color":"#FFE53935"}},{"insert":" means to agree with God that we are not perfect, there are things in our lives that are wrong, and that we want Christ to forgive us as we turn away from sins.\n\nTo "},{"insert":"Surrender","attributes":{"color":"#FFE53935"}},{"insert":" means to allow Christ to be the final authority in our lives and to live in order to please Him and not ourselves.  It doesn’t mean that we have to be perfect but that we will try our best to please Christ.\n\nPrayer of Repentance"},{"insert":"\n","attributes":{"header":2,"align":"center"}},{"insert":"“Dear Lord, I confess that I have sinned and don’t deserve to be with You in heaven. I believe that Jesus dies to pay the price of my sins. Please forgive me, come into my heart, be the Lord of my life and. Help me to live for You from now on. In Jesus’ name, I pray. Amen”"},{"insert":"\n\n","attributes":{"align":"center"}},{"insert":"\n"}]""";

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.setCurrentScreen(screenName: 'Verse: Romans 6:23');
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
                    Flexible(child: quill.QuillEditor.basic(controller: controller, readOnly: true)),
                    const SizedBox(height: 32)
                  ]))))
    ]));
  }
}
