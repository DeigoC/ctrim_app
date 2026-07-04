import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/pages/personal/view_user_roles_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/user_tag_helpers.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:ctrim_app/widgets/user_tag_chip.dart';
import 'package:ctrim_app/widgets/user_tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserSelectorDialog extends StatefulWidget {
  const UserSelectorDialog(
      {super.key,
      required this.alreadySelectedUIDs,
      required this.onSelected,
      this.includeCurrentUser = false,
      this.allowTaskCheck = false});
  final List<String> alreadySelectedUIDs;
  final bool includeCurrentUser, allowTaskCheck;
  final void Function(String) onSelected;

  @override
  State<UserSelectorDialog> createState() => _UserSelectorDialogState();
}

class _UserSelectorDialogState extends State<UserSelectorDialog> {
  late final TextEditingController _tecSearch;
  Set<String> _selectedTagIDs = {};

  @override
  void initState() {
    _tecSearch = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _tecSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (_, appContext, __) {
      final users = appContext.allUsers
          .where((e) =>
              !widget.alreadySelectedUIDs.contains(e.id) &&
              e.fullname.toLowerCase().contains(_tecSearch.text.toLowerCase().trim()) &&
              UserTagHelpers.userMatchesTagFilter(user: e, selectedTagIDs: _selectedTagIDs))
          .toList();

      if (!widget.includeCurrentUser) {
        users.removeWhere((e) => e.id == appContext.currentUser.id);
      }

      return Dialog(
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _tecSearch,
          decoration: const InputDecoration(label: Text('Search'), prefixIcon: Icon(Icons.search)),
          onChanged: (_) {
            setState(() {
              // change list
            });
          },
        ),
        UserTagFilterBar(
          tags: appContext.allTags,
          selectedTagIDs: _selectedTagIDs,
          onSelectionChanged: (selected) => setState(() => _selectedTagIDs = selected),
        ),
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, index) {
                  final thisU = users[index];
                  final userTags = UserTagHelpers.tagsForUser(user: thisU, allTags: appContext.allTags);
                  return ListTile(
                    leading: MyUserAvatar(thisU),
                    title: Text(thisU.fullname),
                    subtitle: userTags.isEmpty ? null : UserTagChipRow(tags: userTags, dense: true),
                    isThreeLine: userTags.isNotEmpty,
                    onTap: () => _onSelectedClick(thisU.id),
                    trailing: _buildTrailing(thisU),
                  );
                }))
      ])));
    });
  }

  Widget? _buildTrailing(final User selectedUser) {
    if (widget.allowTaskCheck) {
      return IconButton(onPressed: () => _onOpenUserTasks(selectedUser), icon: const Icon(Icons.checklist));
    }
    return null;
  }

  // * LOGIC
  // remember we could add a field to show a confirmation?
  void _onSelectedClick(String uid) {
    widget.onSelected(uid);
    Navigator.of(context).pop();
  }

  void _onOpenUserTasks(final User selectedUser) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewUserRolesPage(selectedUser: selectedUser)));
  }
}
