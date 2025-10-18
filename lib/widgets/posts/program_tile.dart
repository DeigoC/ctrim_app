import 'package:avatar_stack/positions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      const SizedBox(height: 12),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(programEntry['title'],
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ))),
      const SizedBox(height: 8),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  timeString,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ))
    ];

    debugPrint('Program entry is: $programEntry');
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonal(
                onPressed: () => onTap(programEntry),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.expand_less, size: 18),
                    SizedBox(width: 4),
                    Text('Show Less'),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => onEditClick(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 4),
                    Text('Edit Task'),
                  ],
                ),
              ),
            ],
          )));
    } else {
      children.add(
        Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: FilledButton.tonal(
                onPressed: () => onTap(programEntry),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.expand_less, size: 18),
                    SizedBox(width: 4),
                    Text('Show Less'),
                  ],
                ),
              ),
            )),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _buildTile(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (kIsWeb) {
      return InkWell(
        onTap: () => onTap(programEntry),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Flexible(
                flex: 2,
                child: ListTile(
                    title: Text(
                      programEntry['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: (programEntry['detail'] as String).isNotEmpty
                        ? Text(
                            programEntry['detail'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          )
                        : null,
                    leading: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getTimeLeadingText(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
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
        ),
      );
    }
    return ListTile(
      title: Text(
        programEntry['title'],
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: (programEntry['detail'] as String).isNotEmpty
          ? Text(
              programEntry['detail'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            )
          : null,
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _getTimeLeadingText(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
