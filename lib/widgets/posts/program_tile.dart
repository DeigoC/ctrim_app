import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
      title: Text(programEntry['title'], maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(programEntry['detail'], maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: Text(_getTimeLeadingText()),
      onTap: () => onTap(programEntry),
      trailing: _buildTileTrailing(context),
    );
  }

  Widget? _buildTileTrailing(BuildContext context) {
    final List<String> assignees = List<String>.from(programEntry['uids']);
    if (assignees.isEmpty) return null;

    final List<ImageProvider> avatars = List<ImageProvider>.empty(growable: true);
    final allUsers = Provider.of<AppContext>(context, listen: false).allUsers;

    for (final uid in assignees) {
      final thisU = allUsers.firstWhere((user) => user.id.compareTo(uid) == 0);
      if (thisU.imgSrc.isNotEmpty) {
        avatars.add(NetworkImage(thisU.imgSrc));
      } else {
        avatars.add(const AssetImage('assets/images/Generic-Profile.jpg'));
      }
    }

    return AvatarStack(width: 90, avatars: avatars);
  }

  // * Logic
  String _getTimeLeadingText() {
    return '${_timeFormat.format(programEntry['start'])}\n${_timeFormat.format(programEntry['end'])}';
  }
}
