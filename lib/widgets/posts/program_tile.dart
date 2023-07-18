import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgramTile extends StatelessWidget {
  const ProgramTile({super.key, required this.onTap, required this.programEntry});
  final Function(Map<String, dynamic>) onTap;
  final Map<String, dynamic> programEntry;

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static final settings = RestrictedAmountPositions(
    maxAmountItems: 3,
    maxCoverage: 0.4,
    minCoverage: 0.4,
  );

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        programEntry['detail'],
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Text(_getTimeLeadingText()),
      // subtitle: Text(
      //   _getAssineeNames(),
      //   maxLines: 2,
      // ),
      onTap: () => onTap(programEntry),
      trailing: SizedBox(
        width: 90,
        child: AvatarStack(settings: settings, avatars: const [
          NetworkImage(
              'https://static.wikia.nocookie.net/garfield/images/9/9f/GarfieldCharacter.jpg/revision/latest?cb=20180421131132'),
          NetworkImage(
              'https://static.wikia.nocookie.net/garfield/images/9/9f/GarfieldCharacter.jpg/revision/latest?cb=20180421131132'),
          NetworkImage(
              'https://static.wikia.nocookie.net/garfield/images/9/9f/GarfieldCharacter.jpg/revision/latest?cb=20180421131132'),
        ]),
      ),
    );
  }

  // * Logic
  String _getTimeLeadingText() {
    return '${_timeFormat.format(programEntry['start'])}\n${_timeFormat.format(programEntry['end'])}';
  }

  String _getAssineeNames() {
    return 'Diego C., Claudette C., and Dana C.';
  }
}
