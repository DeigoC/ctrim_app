import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';

import '../../utility/app_context.dart';

class PortadownChurchPage extends StatelessWidget {
  const PortadownChurchPage({super.key});

  static const String _json = r"""
[{"insert":"Edizon and his wife Veriza are two of the founding members of the CTRIM (Christ the Redeemer International Ministries) Church since 2012. The Sandoval couple have become an important part of its continuous success story up to this day.\n\nEdizon started to lead one caregroup, which is a small group of people who gathers weekly focused on the growth of its members centred on the Word of God! Eventually, it grew up to 4-5 caregroups every week, which were led by other disciples who were raised up from the said caregroups.\n\nWith their passion and love for God, they continually pursue to fulfil the great commission of Jesus Christ by winning, consolidating, discipling and sending people through caregroups.\n\nBefore they were launched as pastors, Edizon served as one of the main worship leaders of the CTRIM Church and became a youth coordinator for several years. Veriza served as one of the Sunday school teachers, assistant coordinator for Women's Network and a cell leader.\n\nCurrently, Edizon is still currently working full time as Deputy Charge Nurse In an Operating Theatres in Belfast City, Northern Ireland while Veriza is doing part time Shift Manager in McDonalds in Lisburn City, Northern Ireland to have more time for childcare and ministry.\n\nLast May 2019, they were launched as pastors of CTRIM in Portadown and areas beyond. Since their launch, Edizon & Veriza have seen how much God moved in their local church together with their destiny and calling: connecting people to Christ and to the church. They strongly believe that our best days and blest days are still to come, and the multitudes of souls are waiting to be won and become disciples of Christ and in turn, they become disciple makers themselves for the advancement of the kingdom of Christ.\n\nEdizon and Riza have been married since 2011 with two beautiful children: Epaphroditus (born 2014) and Asenath-Faith (born 2017). In their spare time, they love to spend it together as a family, may it be in the house or going out for coffee or dining out.\n\nYou can connect with Edizon and Riza through email and social media for prayer requests or to express interest and to join one of their caregroups.\n\n"}]""";

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.setCurrentScreen(screenName: 'Church Info: Portadown');
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 0;
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(jsonDecode(_json)), selection: const TextSelection.collapsed(offset: 0));

    return Scaffold(
        // appBar: AppBar(title: const Text('Portadown'), actions: const [InfoAction(json: _json)]),
        appBar: AppBar(title: const Text('Portadown')),
        body: SingleChildScrollView(
            child: Padding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/port2.jpg',
                height: webHorizontalPadding != 0 ? MediaQuery.of(context).size.height * 0.45 : null,
              ),
              const SizedBox(height: 8),
              quill.QuillProvider(
                configurations: quill.QuillConfigurations(controller: controller),
                child: Flexible(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: quill.QuillEditor.basic(
                          configurations: const quill.QuillEditorConfigurations(readOnly: true),
                        ))),
              ),
              const SizedBox(height: 32)
            ],
          ),
        )));
  }
}
