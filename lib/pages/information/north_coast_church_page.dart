import 'package:flutter/material.dart';

class NorthCoastChurchPage extends StatelessWidget {
  const NorthCoastChurchPage({super.key});

  static const String _info = """
At the beginning of 2018, James and his wife, Nelyn, took a major step of faith and planted Christ The Redeemer International Ministries Church on July 10, 2018 with a dream of impacting the Causeway Coast area for the Kingdom of God.

James stepped down from his full time Assistant Manager role from a McDonalds in Belfast City, and has since relocated here at Coleraine. He still works at McDonalds but only on a part time basis, in order to have more time in doing the ministry in his new role as the pastor of CTRIM North Coast.

Nelyn, on the other hand, has been a full time mum from 2016. After Julia, their third child, Nelyn left her position at Tesco to focus on the kids , as well as proving herself to be of great help to James in growing the ministry.

Since the launch, Christ the Redeemer International Ministries North Coast has seen a steady growth in its disciples and is looking towards another church plant in the city of Derry/ Londonderry.

James and Nelyn have a heart for multiplication and a passion for making disciples and disciple makers.

James and Nelyn have been living in their calling to serve God and the church ever since. They are continually amazed at how God has used this local church to move people towards Christ, community and their calling. They firmly believe that the best is yet to come for Christ the Redeemer International Ministries North Coast and for the Causeway Coast.

James and Nelyn have been married since March 2000 and now have 4 beautiful children: Patrick (17) , Denise (16), Julia (5), and Avery (1). With their spare time, James and Nelyn love to do a variety of activities together - watching movies, going for coffee, whether dining out or just grabbing a burger, these two are absolutely inseparable!

You can connect with James and Nelyn Baccay personally through email and through their social media.

""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('North Coast')),
        body: ListView(children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              'https://public.curryscloudbackup.co.uk/webservice/accounts/00000000000000000000000000000000/sharing/withme/bppdegjn/images/9d2c11c380e347feab493df67315aef3?preset=previewpng&cacheKey=133351053840000000&width=1500&height=1500',
              fit: BoxFit.contain,
            ),
          ),
          const Padding(
              padding: EdgeInsets.all(8.0),
              child: SelectableText(_info, style: TextStyle(fontSize: 16), textAlign: TextAlign.justify))
        ]));
  }
}
