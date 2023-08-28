import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';

import '../../utility/app_context.dart';

class NorthCoastChurchPage extends StatelessWidget {
  const NorthCoastChurchPage({super.key});

  static const String _json = r"""
[{"insert":"At the beginning of 2018, James and his wife, Nelyn, took a major step of faith and planted Christ The Redeemer International Ministries Church on July 10, 2018 with a dream of impacting the Causeway Coast area for the Kingdom of God.\n\nJames stepped down from his full time Assistant Manager role from a McDonalds in Belfast City, and has since relocated here at Coleraine. He still works at McDonalds but only on a part time basis, in order to have more time in doing the ministry in his new role as the pastor of CTRIM North Coast.\n\nNelyn, on the other hand, has been a full time mum from 2016. After Julia, their third child, Nelyn left her position at Tesco to focus on the kids , as well as proving herself to be of great help to James in growing the ministry.\n\nSince the launch, Christ the Redeemer International Ministries North Coast has seen a steady growth in its disciples and is looking towards another church plant in the city of Derry/ Londonderry.\n\nJames and Nelyn have a heart for multiplication and a passion for making disciples and disciple makers.\n\nJames and Nelyn have been living in their calling to serve God and the church ever since. They are continually amazed at how God has used this local church to move people towards Christ, community and their calling. They firmly believe that the best is yet to come for Christ the Redeemer International Ministries North Coast and for the Causeway Coast.\n\nJames and Nelyn have been married since March 2000 and now have 4 beautiful children: Patrick, Denise, Julia, and Avery. With their spare time, James and Nelyn love to do a variety of activities together - watching movies, going for coffee, whether dining out or just grabbing a burger, these two are absolutely inseparable!\n\nYou can connect with James and Nelyn Baccay personally through email and through their social media.\n\n"}]""";

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.setCurrentScreen(screenName: 'Church Info: North Coast');
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 0;
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(jsonDecode(_json)), selection: const TextSelection.collapsed(offset: 0));

    return Scaffold(
        // appBar: AppBar(title: const Text('North Coast'), actions: const [InfoAction(json: _json)]),
        appBar: AppBar(title: const Text('North Coast')),
        body: SingleChildScrollView(
            child: Padding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/northC2.jpg',
                height: webHorizontalPadding != 0 ? MediaQuery.of(context).size.height * 0.45 : null,
              ),
              const SizedBox(height: 8),
              Flexible(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: quill.QuillEditor.basic(controller: controller, readOnly: true, autoFocus: false))),
              const SizedBox(height: 32)
            ],
          ),
        )));
  }
}
