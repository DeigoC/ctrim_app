import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/cell_group_roster_cache.dart';
import '../../utility/cell_group_roster_helpers.dart';
import '../../widgets/common/load_progress_body.dart';
import 'view_user_profile_page.dart';

/// Resolves a person id from the route then shows [ViewUserProfilePage].
///
/// In-app opens should pass the session [User] as extra so directory-gated
/// profiles (placeholders, hidden) still open. Cold links apply
/// [canOpenPersonPermalink].
class OpenPersonPage extends StatefulWidget {
  const OpenPersonPage({
    super.key,
    required this.userId,
    this.initialUser,
  });

  final String userId;
  final User? initialUser;

  @override
  State<OpenPersonPage> createState() => _OpenPersonPageState();
}

class _OpenPersonPageState extends State<OpenPersonPage> {
  final UserDBManager _userDb = UserDBManager();

  User? _user;
  Object? _error;
  bool _missing = false;
  bool _loading = true;
  late final bool _fromInApp;

  @override
  void initState() {
    super.initState();
    final extra = widget.initialUser;
    _fromInApp = extra != null && extra.id == widget.userId;
    if (_fromInApp) {
      _user = extra;
      _loading = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resolveUser();
    });
  }

  Future<void> _resolveUser() async {
    setState(() {
      _loading = true;
      _error = null;
      _missing = false;
    });

    if (widget.userId.isEmpty) {
      setState(() {
        _loading = false;
        _missing = true;
      });
      return;
    }

    final appContext = context.read<AppContext>();
    User? resolved = appContext.userById(widget.userId);

    try {
      if (resolved == null) {
        resolved = await _userDb.fetchUserIfExists(widget.userId);
        if (!mounted) return;
        if (resolved != null) {
          appContext.addOrUpdateUser(resolved);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
      return;
    }

    if (!mounted) return;

    var leadsCellGroup = false;
    if (resolved != null &&
        !_fromInApp &&
        resolved.isPlaceholder &&
        !appContext.currentUser.isAreaAdmin) {
      await CellGroupRosterCache.ensureLoaded(
        appContext.allCellGroups.where((g) => !g.isArchived).map((g) => g.id),
      );
      if (!mounted) return;
      leadsCellGroup = CellGroupRosterHelpers.actorLeadsGroupContainingUser(
        actor: appContext.currentUser,
        targetUserId: resolved.id,
        catalogue: appContext.allCellGroups,
      );
    }

    if (resolved == null ||
        (!_fromInApp &&
            !canOpenPersonPermalink(
              user: resolved,
              viewer: appContext.currentUser,
              leadsCellGroupContainingUser: leadsCellGroup,
            ))) {
      setState(() {
        _user = null;
        _loading = false;
        _missing = true;
      });
      return;
    }

    setState(() {
      _user = resolved;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user != null) {
      return ViewUserProfilePage(selectedUser: user);
    }

    final l10n = AppLocalizations.of(context)!;
    final Object? progressError;
    final String errorTitle;
    if (_missing) {
      progressError = l10n.openPersonNotFoundBody;
      errorTitle = l10n.openPersonNotFoundTitle;
    } else if (_error != null) {
      progressError = _error;
      errorTitle = l10n.openPersonLoadErrorTitle;
    } else {
      progressError = null;
      errorTitle = l10n.openPersonLoadErrorTitle;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.openPersonPageTitle)),
      body: LoadProgressBody(
        message: l10n.openPersonLoading,
        completedSteps: _loading ? 0 : 1,
        totalSteps: 1,
        error: progressError,
        errorTitle: errorTitle,
        onRetry: progressError == null ? null : _resolveUser,
      ),
    );
  }
}
