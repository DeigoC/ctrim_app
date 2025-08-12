import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_selector_dialog.dart';

class ViewMetaLogsPage extends StatefulWidget {
  const ViewMetaLogsPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<ViewMetaLogsPage> createState() => _ViewMetaLogsPageState();
}

class _ViewMetaLogsPageState extends State<ViewMetaLogsPage> {
  late final AppContext _appContext;
  late final List<String> _originalContribtors;
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy. HH:mm');
  @override
  void initState() {
    _originalContribtors = List.from(widget.eventContext.metadata.contributorUIDs, growable: false);
    _appContext = Provider.of<AppContext>(context, listen: false);
    _appContext.analytics.logScreenView(screenName: 'Meta-logs for Post:${widget.eventContext.id}');
    widget.eventContext.log.orderLogsBackwards(); // needed?
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvoked: (_) {
          _checkForChangesToContributors();
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Change History'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
          ),
          body: _buildWithData(context),
        ));
  }

  Widget _buildWithData(BuildContext context) {
    final List<User> allUsers = _appContext.allUsers;
    final User mainAdmin = allUsers.firstWhere((e) => e.id.compareTo(widget.eventContext.metadata.authorUID) == 0);
    final List<User> selectedUsers =
        allUsers.where((element) => widget.eventContext.metadata.contributorUIDs.contains(element.id)).toList();
    final bool isAuthor = widget.eventContext.isUserAuthor(_appContext.currentUser.id);
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding + 16),
          sliver: SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 16),
            // Author Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Author',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        mainAdmin.fullname,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      subtitle: Text(
                        'Event creator and owner',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                      leading: MyUserAvatar(mainAdmin),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Contributors Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.group,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contributors',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'People who can edit this event',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (isAuthor)
                          FilledButton.icon(
                            onPressed: _viewPotentialContributorsTap,
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: const Text('Add'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildContributors(selectedUsers),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ])),
        ),
        // Change History Section
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding + 16),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Change History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding + 16),
          sliver: widget.eventContext.log.logs.isEmpty
              ? SliverToBoxAdapter(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history_edu,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No changes yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Event changes and updates will appear here as they happen.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList.builder(
                  itemCount: widget.eventContext.log.logs.length,
                  itemBuilder: (_, index) {
                    final thisEntry = widget.eventContext.log.logs[index];
                    final thisU = allUsers.firstWhere((e) => e.id.compareTo(thisEntry['uid']) == 0);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          thisEntry['log'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle: Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Text(
                            _dateFormat.format(thisEntry['ts']),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ),
                        leading: MyUserAvatar(thisU),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                        onTap: () => _showFullLog(thisEntry, webHorizontalPadding),
                      ),
                    );
                  }),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 24),
        ),
      ],
    );
  }

  Widget _buildContributors(final List<User> selectedUsers) {
    if (selectedUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_off,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'No contributors added yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _showContributors(selectedUsers),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: MyAvatarStack(
                users: selectedUsers,
                appDir: _appContext.appDir,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  // * Logic
  void _showFullLog(final Map<String, dynamic> entry, final double horizontalPadding) {
    final thisU = _appContext.getUserFromID(entry['uid']);
    showDialog(
        context: context,
        builder: (_) => Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding + 16),
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          MyUserAvatar(thisU),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  thisU.fullname,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                ),
                                Text(
                                  _dateFormat.format(entry['ts']),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry['log'],
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        height: 1.5,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FilledButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }

  void _showContributors(final List<User> selectedUsers) {
    showDialog(
        context: context,
        builder: (_) {
          return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.group,
                            color: Theme.of(context).colorScheme.onSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contributors',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                              ),
                              Text(
                                '${selectedUsers.length} contributor${selectedUsers.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: selectedUsers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final thisU = selectedUsers[index];
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              thisU.fullname,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            leading: MyUserAvatar(thisU),
                            subtitle: Text(
                              thisU.location,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                            trailing: widget.eventContext.isUserAuthor(_appContext.currentUser.id)
                                ? IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () => _onRemoveContributorClick(thisU),
                                    tooltip: 'Remove contributor',
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ));
        });
  }

  void _onRemoveContributorClick(final User thisU) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_remove,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Remove Contributor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove ${thisU.fullname} as a contributor?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'They will no longer be able to edit this event.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _removeContributor(thisU.id);
              Navigator.of(context).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close contributors dialog
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeContributor(final String removedUID) {
    setState(() {
      widget.eventContext.metadata.contributorUIDs.remove(removedUID);
      widget.eventContext.contributorAdditionUIDs.remove(removedUID);
      widget.eventContext.contributorRemovalUIDs.add(removedUID);
      widget.eventContext.allowSavingOfTheEdit();
    });
  }

  void _viewPotentialContributorsTap() {
    final List<String> alreadySelected = List<String>.from(widget.eventContext.metadata.contributorUIDs);
    alreadySelected.add(widget.eventContext.metadata.authorUID);

    showDialog(
        context: context,
        builder: (_) =>
            UserSelectorDialog(alreadySelectedUIDs: alreadySelected, onSelected: (newID) => _addContributor(newID)));
  }

  void _addContributor(final String newContributorID) {
    setState(() {
      // bothersome? just put all of this in eventContext?
      widget.eventContext.metadata.contributorUIDs.add(newContributorID);
      widget.eventContext.contributorAdditionUIDs.add(newContributorID);
      widget.eventContext.contributorRemovalUIDs.remove(newContributorID);
      widget.eventContext.allowSavingOfTheEdit();
    });
  }

  void _checkForChangesToContributors() {
    bool haveContributorsChange = false;
    if (_originalContribtors.length != widget.eventContext.metadata.contributorUIDs.length) {
      haveContributorsChange = true;
    } else {
      for (final newContributorID in widget.eventContext.metadata.contributorUIDs) {
        if (!_originalContribtors.contains(newContributorID)) {
          haveContributorsChange = true;
          break;
        }
      }
    }

    if (haveContributorsChange) {
      widget.eventContext.allowSavingOfTheEdit();
    }
  }
}
