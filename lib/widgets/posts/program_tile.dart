import 'dart:io';

import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
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
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        child: child,
      ),
      child: selected ? _buildExtendedView(context) : _buildTile(context),
    );
  }

  Widget _buildExtendedView(BuildContext context) {
    final List<Widget> children = [
      const SizedBox(height: 16),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(programEntry['title'], style: const TextStyle(fontSize: 21))),
      const SizedBox(height: 4),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('${_timeFormat.format(programEntry['start'])} - ${_timeFormat.format(programEntry['end'])}',
              textAlign: TextAlign.start))
    ];

    if ((programEntry['detail'] as String).isNotEmpty) {
      children.addAll([
        Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(programEntry['detail'], style: const TextStyle(fontSize: 16), textAlign: TextAlign.start))
      ]);
    }

    if (!programEntry['for_guests']) {
      children
          .add(const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('(Do not show for Guests)')));
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
              TextButton(onPressed: () => onTap(programEntry), child: const Text('Show less')),
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
    return ListTile(
      title: Text(programEntry['title'], maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: (programEntry['detail'] as String).isNotEmpty
          ? Text(programEntry['detail'], maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      leading: Text(_getTimeLeadingText()),
      onTap: () => onTap(programEntry),
      trailing: _buildTileTrailing(context),
    );
  }

  Widget? _buildTileTrailing(BuildContext context) {
    final List<String> assignees = programEntry['uids'];
    if (assignees.isEmpty) return null;

    final List<ImageProvider> avatars = List<ImageProvider>.empty(growable: true);
    final appContext = Provider.of<AppContext>(context, listen: false);
    final allUsers = appContext.allUsers;

    for (final uid in assignees) {
      final thisU = allUsers.firstWhere((user) => user.id.compareTo(uid) == 0);
      if (thisU.imgSrc.isNotEmpty) {
        final path = '${appContext.appDir}/user_imgs/${thisU.id}.png';
        avatars.add(FileImage(File(path)));
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
