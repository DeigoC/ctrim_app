import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utility/app_context.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class BelfastChurchPage extends StatelessWidget {
  const BelfastChurchPage({super.key});

  static const String _json = r"""
[{"insert":"Pastor Deo"},{"insert":"\n","attributes":{"header":1}},{"insert":"Deo Valdez is the Senior Founding Pastor of Christ The Redeemer International Ministries in Belfast Northern Ireland. A pentecostal, non-denominational, independent discipling Church.\n\nThe Chuch is now heading to it's 8th year with a regular Sunday service attendance of 100-150 people and about 300 people in the Cellgroups in different places in Northern Ireland throughout the week, with three daughter churches.\n\nHe was born on January 13,1969 at Aliaga, Nueva-Ecija, Philippines and his service to the Lord began in 1995 until present. He pioneered and pastor Churches in the Philippines before coming over at Northern Ireland last 2006.\n\nGraduated and ordained as a minister of the gospel at the Assemblies of God, Philippines. He studied at Nueva Ecija Bible Institute. He also studied Apologetics and Church administration at Bethel Bible College. Finished his theology at Shalom Bible Institute. Licensed as a minister under the Assemblies of God. He also taught Theology in the Bible School before coming to Northern Ireland.\n\nPastor Deo is the Innovator and Chief Strategist of 4XD Acts DNA Strategic Discipleship.\n\nPastora Ingrid"},{"insert":"\n","attributes":{"header":1}},{"insert":"Ingrid Valdez is the Deputy Pastor - P.E.P.S.O.L. Directress & Chief Operating Officer of Christ The Redeemer International Ministries. Ingrid was born on April 24,1978 at Marikina, Metro Manila, Philippines. She graduated from Manuel V.Gallego Foundation Colleges in 1999 with a degree of Bachelor of Science In Physical Therapy.\n\nIngrid started to be in the ministry at the age of 11 years old at Crossworld Church,her mother Church in the Philippines like leading the youth, praise and worship team including the tambourine ministry. She also completed a number of leadership trainings including pastoral care in the Philippines before coming to Northern Ireland last 2004.\n\nDeo and Ingrid together served as mentors to other Pastors and leaders in the Philippines, England and Australia in fulfillment of the vision of winning more people and discipling more people for God.\n\nEquipping and empowering God's people. Mentoring disciples and leading the next generation. Deo and Ingrid are blessed to have three wonderful children - Peter James, Eliz Jayne and Christel Zoe.\n\nFor many years of God's faithfulness, Deo and Ingrid had proven that it is the Holy Spirit at work through them and in them. With a strong desire and passion to win souls and disciple more people for God. They have travelled in the nations of the Philippines, United Kingdom and Australia conducting conferences and mentoring Pastors and leaders.\n"}]""";

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.setCurrentScreen(screenName: 'Church Info: Belfast');
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 0;
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(jsonDecode(_json)), selection: const TextSelection.collapsed(offset: 0));

    return Scaffold(
        // appBar: AppBar(title: const Text('Belfast'), actions: const [InfoAction(json: _json)]),
        appBar: AppBar(title: const Text('Belfast')),
        body: SingleChildScrollView(
            child: Padding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/bel2.jpg',
                height: webHorizontalPadding != 0 ? MediaQuery.of(context).size.height * 0.45 : null,
              ),
              const SizedBox(height: 8),
              Flexible(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: quill.QuillEditor.basic(controller: controller, readOnly: true))),
              const SizedBox(height: 32)
            ],
          ),
        )));
  }
}
