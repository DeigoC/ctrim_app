import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../widgets/common/load_progress_body.dart';
import 'view_event_page.dart';

/// Resolves a post id from the route (session, extra, or fetch) then shows
/// [ViewEventPage]. In-app opens should pass the session [EventHead] as extra
/// so discard-on-exit still mutates the shared instance.
class OpenPostPage extends StatefulWidget {
  const OpenPostPage({
    super.key,
    required this.postId,
    this.initialHead,
  });

  final String postId;
  final EventHead? initialHead;

  @override
  State<OpenPostPage> createState() => _OpenPostPageState();
}

class _OpenPostPageState extends State<OpenPostPage> {
  final EventHeadDBManager _headDb = EventHeadDBManager();

  EventHead? _head;
  Object? _error;
  bool _missing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final extra = widget.initialHead;
    if (extra != null && extra.id == widget.postId) {
      _head = extra;
      _loading = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resolveHead();
    });
  }

  Future<void> _resolveHead() async {
    setState(() {
      _loading = true;
      _error = null;
      _missing = false;
    });

    if (widget.postId.isEmpty) {
      setState(() {
        _loading = false;
        _missing = true;
      });
      return;
    }

    final sessionHead = context.read<AppContext>().headById(widget.postId);
    if (sessionHead != null) {
      setState(() {
        _head = sessionHead;
        _loading = false;
      });
      return;
    }

    try {
      final fetched = await _headDb.fetchHeadIfExists(widget.postId);
      if (!mounted) return;
      if (fetched == null) {
        setState(() {
          _loading = false;
          _missing = true;
        });
        return;
      }
      context.read<AppContext>().addOrUpdatePostHead(fetched);
      setState(() {
        _head = fetched;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final head = _head;
    if (head != null) {
      return ViewEventPage(eventHead: head);
    }

    final l10n = AppLocalizations.of(context)!;
    final Object? progressError;
    final String errorTitle;
    if (_missing) {
      progressError = l10n.openPostNotFoundBody;
      errorTitle = l10n.openPostNotFoundTitle;
    } else if (_error != null) {
      progressError = _error;
      errorTitle = l10n.openPostLoadErrorTitle;
    } else {
      progressError = null;
      errorTitle = l10n.openPostLoadErrorTitle;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.openPostPageTitle)),
      body: LoadProgressBody(
        message: l10n.openPostLoading,
        completedSteps: _loading ? 0 : 1,
        totalSteps: 1,
        error: progressError,
        errorTitle: errorTitle,
        onRetry: progressError == null ? null : _resolveHead,
      ),
    );
  }
}
