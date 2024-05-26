import 'package:flutter/material.dart';

class TimedButtonDialog extends StatefulWidget {
  const TimedButtonDialog({super.key});

  @override
  State<TimedButtonDialog> createState() => TimedButtonDialogState();
}

class TimedButtonDialogState extends State<TimedButtonDialog> {
  bool _enabledOk = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 4)).then((_) {
        setState(() {
          _enabledOk = true;
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
              foregroundDecoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  image: DecorationImage(image: AssetImage('assets/info/opening.gif'), fit: BoxFit.fill)),
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/info/opening.gif') // so jank lol! It works though
                  )),
          const SizedBox(height: 16),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('View Posts in Detail!', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Remember that you can click on these posts to view more information.',
                  style: TextStyle(fontSize: 16))),
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                    onPressed: _enabledOk ? () => Navigator.of(context).pop() : null, child: const Text('Ok')),
              )),
          const SizedBox(height: 16)
        ])));
  }
}
