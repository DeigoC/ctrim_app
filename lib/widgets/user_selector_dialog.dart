import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/pages/personal/view_user_roles_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
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
  // inlcude everyone for now, regardless of location
  // we will have a list of userIDs that are not to be shown

  late final TextEditingController _tecSearch;
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
              e.fullname.toLowerCase().contains(_tecSearch.text.toLowerCase().trim()))
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
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, index) {
                  final thisU = users[index];
                  return ListTile(
                    leading: MyUserAvatar(thisU),
                    title: Text(thisU.fullname),
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
