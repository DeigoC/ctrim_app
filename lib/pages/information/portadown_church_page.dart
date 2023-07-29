import 'package:flutter/material.dart';

class PortadownChurchPage extends StatelessWidget {
  const PortadownChurchPage({super.key});

  static const String _info = """
Edizon and his wife Veriza are two of the founding members of the CTRIM (Christ the Redeemer International Ministries) Church since 2012. The Sandoval couple have become an important part of its continuous success story up to this day.

Edizon started to lead one caregroup, which is a small group of people who gathers weekly focused on the growth of its members centred on the Word of God! Eventually, it grew up to 4-5 caregroups every week, which were led by other disciples who were raised up from the said caregroups.

With their passion and love for God, they continually pursue to fulfil the great commission of Jesus Christ by winning, consolidating, discipling and sending people through caregroups.

Before they were launched as pastors, Edizon served as one of the main worship leaders of the CTRIM Church and became a youth coordinator for several years. Veriza served as one of the Sunday school teachers, assistant coordinator for Women's Network and a cell leader.

Currently, Edizon is still currently working full time as Deputy Charge Nurse In an Operating Theatres in Belfast City, Northern Ireland while Veriza is doing part time Shift Manager in McDonalds in Lisburn City, Northern Ireland to have more time for childcare and ministry.

Last May 2019, they were launched as pastors of CTRIM in Portadown and areas beyond. Since their launch, Edizon & Veriza have seen how much God moved in their local church together with their destiny and calling: connecting people to Christ and to the church. They strongly believe that our best days and blest days are still to come, and the multitudes of souls are waiting to be won and become disciples of Christ and in turn, they become disciple makers themselves for the advancement of the kingdom of Christ.

Edizon and Riza have been married since 2011 with two beautiful children: Epaphroditus (born 2014) and Asenath-Faith (born 2017). In their spare time, they love to spend it together as a family, may it be in the house or going out for coffee or dining out.

You can connect with Edizon and Riza through email and social media for prayer requests or to express interest and to join one of their caregroups.

""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Portadown')),
        body: ListView(children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              'https://public.curryscloudbackup.co.uk/webservice/accounts/00000000000000000000000000000000/sharing/withme/bppdegjn/images/b9d347e65e5c4b3cba7baabaf55d8fce?preset=previewpng&cacheKey=133351053840000000&width=1500&height=1500',
              fit: BoxFit.contain,
            ),
          ),
          const Padding(
              padding: EdgeInsets.all(8.0),
              child: SelectableText(_info, style: TextStyle(fontSize: 16), textAlign: TextAlign.justify))
        ]));
  }
}
