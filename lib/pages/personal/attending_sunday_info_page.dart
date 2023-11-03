import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../utility/app_context.dart';

class AttendingSundayServicePage extends StatelessWidget {
  const AttendingSundayServicePage({super.key});
  static const String _json = r"""
[{"insert":"Sunday Service"},{"insert":"\n","attributes":{"header":1,"align":"center"}},{"insert":"\nHot drinks & light snacks will be made available after the service at the hospitality room. Food is not to be taken & eaten at the main sanctuary.\n\nSunday School"},{"insert":"\n","attributes":{"header":2}},{"insert":"All parents are to collect their children at the Sunday school room building after the service & executive meeting\n\nCleaning"},{"insert":"\n","attributes":{"header":2}},{"insert":"As per our last cellgroup leader’s meeting on 05/03/23, every department will now be responsible to clean their own respective areas & every department leaders to delegate responsibilities including the final checks to their team.\n\nBuilding department coordinators to please check that everything was cleaned and tidied excellently.\n\nLet us all continue to greet one another with a hand wave or elbow bump.\n\n"},{"insert":"PLEASE BRING YOUR OWN DRINKING WATER","attributes":{"bold":true}},{"insert":"\n","attributes":{"align":"center"}},{"insert":"\nPlease make yourselves familiar of our risk assessments and the information below.\n\nRisk Assessment"},{"insert":"\n","attributes":{"header":2}},{"insert":"\nWe just want to make you continually aware of some guidelines we observe with regards to reducing the risk of Covid-19 from spreading in our gatherings. \n\nAs we are all aware, Covid-19 is still circulating within the community. It is still possible to catch and spread Covid-19, even if you are fully vaccinated. So we have put certain measures in place (in accordance with the guidance found on nidrect.gov.uk), to ensure everyone's safety and to reduce the risk of Covid-19 from spreading.\n\n1. Symptoms"},{"insert":"\n","attributes":{"header":3}},{"insert":"As part of our risk assessment for this coming Sunday, if you have the following symptoms, please stay at home:\nhigh temperature – this means you feel hot to touch on your chest or back (you do not need to measure your temperature)."},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"new, continuous cough – this means coughing a lot for more than an hour, or 3 or more coughing episodes in 24 hours (if you usually have a cough, it may be worse than usual)."},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"loss or change to your sense of smell or taste – this means you've noticed you cannot smell or taste anything, or things smell or taste different to normal."},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\n2. Testing "},{"insert":"\n","attributes":{"header":3}},{"insert":"We recommend that you do a Lateral Flow Test before you go, at least a day before the meeting. By taking a Lateral Flow Test before you meet up, you can help protect the people close to you and reduce the pressures on health and social care services. \n\n3. Face Covering"},{"insert":"\n","attributes":{"header":3}},{"insert":"We recommend the wearing of a FACE COVERING. -Although wearing a face covering is no longer a legal requirement, they are still strongly recommended in indoor areas where you come into contact with people you do not usually meet.\n\n4. Sanitation"},{"insert":"\n","attributes":{"header":3}},{"insert":"We will have hand sanitation areas onsite. \n\n5. Read More "},{"insert":"\n","attributes":{"header":3}},{"insert":"A detailed copy of our risk assessment will be posted as well, so please make yourselves familiar with it. \n\nRemember Your 4 B’s!"},{"insert":"\n","attributes":{"header":2}},{"insert":"\nPlease don’t forget to bring your bible, notebook & ballpen for taking notes, you can also use your ipad or mobile phone for taking notes but please put it in silence during our service. Most of all let us bring a great expectation to receive from the lord, be changed & tranformed by him!\n"}]""";

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false)
        .analytics
        .setCurrentScreen(screenName: 'Personal: Attending Sunday Service');
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(jsonDecode(_json)), selection: const TextSelection.collapsed(offset: 0));

    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 0;

    return Scaffold(
        body: CustomScrollView(slivers: [
      const SliverAppBar(floating: true, snap: true),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
        sliver: SliverToBoxAdapter(
            child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: quill.QuillProvider(
                      configurations: quill.QuillConfigurations(controller: controller),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                            child: quill.QuillEditor.basic(
                          configurations: const quill.QuillEditorConfigurations(readOnly: true),
                        )),
                        const SizedBox(height: 32)
                      ]),
                    )))),
      )
    ]));
  }
}
