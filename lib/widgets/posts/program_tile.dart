import 'package:avatar_stack/positions.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../my_avatar_stack.dart';
import '../user_avatar.dart';

class ProgramTile extends StatelessWidget {
  const ProgramTile(
      {super.key,
      required this.onTap,
      required this.programEntry,
      required this.selected,
      required this.assignedUsers,
      required this.canEdit,
      required this.onEditClick});
  final Function(Map<String, dynamic>) onTap;
  final Function() onEditClick;
  final Map<String, dynamic> programEntry;
  final bool selected;
  final List<User> assignedUsers;
  final bool canEdit;

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static final settings = RestrictedAmountPositions(
    maxAmountItems: 3,
    maxCoverage: 0.4,
    minCoverage: 0.4,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => SizeTransition(sizeFactor: animation, child: child),
      child: selected ? _buildExtendedView(context) : _buildTile(context),
    );
  }

  Widget _buildExtendedView(BuildContext context) {
    final Duration difference = programEntry['end'].difference(programEntry['start']);
    String diffStr;

    if (difference.inHours > 0) {
      int hours = difference.inHours;
      int minutes = difference.inMinutes.remainder(60); // Remaining minutes

      if (minutes == 0) {
        diffStr = hours == 1 ? '$hours hour' : '$hours hours';
      } else {
        diffStr = hours == 1 ? '$hours hour $minutes minutes' : '$hours hours $minutes minutes';
      }
    } else {
      int minutes = difference.inMinutes;
      diffStr = minutes == 1 ? '$minutes minute' : '$minutes minutes';
    }

    final String timeString = programEntry['for_guests']
        ? '${_timeFormat.format(programEntry['start'])} - ${_timeFormat.format(programEntry['end'])} | $diffStr'
        : '${_timeFormat.format(programEntry['start'])} - ${_timeFormat.format(programEntry['end'])} | $diffStr | Not for guest eyes 👀';

    final List<Widget> children = [
      const SizedBox(height: 8),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(programEntry['title'], style: const TextStyle(fontSize: 21))),
      const SizedBox(height: 4),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(timeString, textAlign: TextAlign.start))
    ];

    if ((programEntry['detail'] as String).isNotEmpty) {
      children.addAll([
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(programEntry['detail'], style: const TextStyle(fontSize: 16), textAlign: TextAlign.start))
      ]);
    }

    if (assignedUsers.isNotEmpty) {
      children.add(const Divider(indent: 16, endIndent: 16));
      for (final user in assignedUsers) {
        children.add(ListTile(
            title: Text(user.fullname),
            leading: MyUserAvatar(user),
            onTap: () => DialogManager.showUserProfile(selectedUser: user, context: context)));
      }
      // children.add(const Divider(indent: 32, endIndent: 32));
    }

    if (canEdit) {
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: [
              TextButton(onPressed: () => onTap(programEntry), child: const Text('Show Less')),
              TextButton(onPressed: () => onEditClick(), child: const Text('Edit Task'))
            ],
          )));
    } else {
      children.add(
        Align(
            alignment: Alignment.center,
            child: TextButton(onPressed: () => onTap(programEntry), child: const Text('Show less'))),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _buildTile(BuildContext context) {
    if (kIsWeb) {
      return InkWell(
        onTap: () => onTap(programEntry),
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: ListTile(
                  title: Text(programEntry['title'], maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: (programEntry['detail'] as String).isNotEmpty
                      ? Text(programEntry['detail'], maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                  leading: Text(_getTimeLeadingText())),
            ),
            Flexible(
              flex: 1,
              child: MyAvatarStack(
                users: (programEntry['uids'] as List<String>)
                    .map((e) => Provider.of<AppContext>(context, listen: false).getUserFromID(e))
                    .toList(),
                appDir: Provider.of<AppContext>(context, listen: false).appDir,
              ),
            ),
          ],
        ),
      );
    }
    return ListTile(
      title: Text(programEntry['title'], maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: (programEntry['detail'] as String).isNotEmpty
          ? Text(programEntry['detail'], maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      leading: Text(_getTimeLeadingText()),
      onTap: () => onTap(programEntry),
      trailing: MyAvatarStack(
        users: (programEntry['uids'] as List<String>)
            .map((e) => Provider.of<AppContext>(context, listen: false).getUserFromID(e))
            .toList(),
        appDir: Provider.of<AppContext>(context, listen: false).appDir,
      ),
    );
  }

  // * Logic
  String _getTimeLeadingText() {
    return '${_timeFormat.format(programEntry['start'])}\n${_timeFormat.format(programEntry['end'])}';
  }
}
