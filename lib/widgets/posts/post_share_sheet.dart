import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';
import '../../utility/post_share_text.dart';
import '../common/action_sheet.dart';
import '../common/app_dialog.dart';

/// App-bar share sheet for an open post: the permalink, or the About write-up.
Future<void> showPostShareSheet({
  required BuildContext context,
  required EventContext eventContext,
  Rect? sharePositionOrigin,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
    ),
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      final colorScheme = Theme.of(sheetContext).colorScheme;
      return ActionSheetShell(
        icon: Icons.share_outlined,
        title: l10n.sharePostSheetTitle,
        subtitle: l10n.sharePostSheetSubtitle,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                ActionSheetOption(
                  icon: Icons.link,
                  color: colorScheme.primary,
                  title: l10n.sharePostLinkTitle,
                  subtitle: l10n.sharePostLinkSubtitle,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_shareLink(
                      context,
                      eventContext,
                      sharePositionOrigin,
                    ));
                  },
                ),
                const SizedBox(height: 8),
                ActionSheetOption(
                  icon: Icons.article_outlined,
                  color: colorScheme.tertiary,
                  title: l10n.sharePostWriteUpTitle,
                  subtitle: l10n.sharePostWriteUpSubtitle,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_shareWriteUp(
                      context,
                      eventContext,
                      sharePositionOrigin,
                    ));
                  },
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _shareLink(
  BuildContext context,
  EventContext eventContext,
  Rect? sharePositionOrigin,
) {
  return _presentShare(
    context: context,
    text: PostShareText.link(eventContext.id),
    title: eventContext.head.title,
    postId: eventContext.id,
    contentType: 'post_link',
    sharePositionOrigin: sharePositionOrigin,
    quietCopy: true,
  );
}

Future<void> _shareWriteUp(
  BuildContext context,
  EventContext eventContext,
  Rect? sharePositionOrigin,
) {
  final l10n = AppLocalizations.of(context)!;
  return _presentShare(
    context: context,
    text: PostShareText.writeUp(
      title: eventContext.head.title,
      postId: eventContext.id,
      body: eventContext.body,
      extractFailedMessage: l10n.sharePostExtractFailed,
    ),
    title: eventContext.head.title,
    postId: eventContext.id,
    contentType: 'post',
    sharePositionOrigin: sharePositionOrigin,
    quietCopy: false,
  );
}

/// Presents the system share sheet. A link with no sheet is copied at once.
/// The write-up falls back to a copy dialog, including when the sheet is dismissed.
Future<void> _presentShare({
  required BuildContext context,
  required String text,
  required String title,
  required String postId,
  required String contentType,
  required Rect? sharePositionOrigin,
  required bool quietCopy,
}) async {
  final analytics = Provider.of<AppContext>(context, listen: false).analytics;
  final params = ShareParams(
    text: text,
    title: title,
    subject: title,
    sharePositionOrigin: kIsWeb ? null : sharePositionOrigin,
  );

  try {
    final result = await SharePlus.instance.share(params);
    if (result.status == ShareResultStatus.success) {
      analytics.logShare(
        contentType: contentType,
        method: 'share',
        itemId: postId,
      );
      return;
    }
    if (result.status == ShareResultStatus.dismissed && !quietCopy) {
      if (!context.mounted) return;
      await _showCopyDialog(context, text, postId, contentType);
      return;
    }
    if (result.status == ShareResultStatus.unavailable) {
      if (!context.mounted) return;
      if (quietCopy) {
        await _copyQuietly(context, text, postId, contentType);
      } else {
        await _showCopyDialog(context, text, postId, contentType);
      }
    }
  } catch (_) {
    if (!context.mounted) return;
    if (quietCopy) {
      await _copyQuietly(context, text, postId, contentType);
    } else {
      await _showCopyDialog(context, text, postId, contentType);
    }
  }
}

Future<void> _copyQuietly(
  BuildContext context,
  String text,
  String postId,
  String contentType,
) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  Provider.of<AppContext>(context, listen: false).analytics.logShare(
        contentType: contentType,
        method: 'copy',
        itemId: postId,
      );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.sharePostLinkCopied)),
  );
}

Future<void> _showCopyDialog(
  BuildContext context,
  String content,
  String postId,
  String contentType,
) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AppDialog(
      icon: Icons.share_outlined,
      title: l10n.sharePostCopyDialogTitle,
      message: l10n.sharePostCopyDialogMessage,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          content,
          style: theme.textTheme.bodySmall,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: AppDialogActions(
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () async {
          await Clipboard.setData(ClipboardData(text: content));
          if (!dialogContext.mounted) return;
          Provider.of<AppContext>(dialogContext, listen: false)
              .analytics
              .logShare(
                contentType: contentType,
                method: 'copy',
                itemId: postId,
              );
          Navigator.of(dialogContext).pop();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.sharePostCopied)),
          );
        },
        confirmLabel: l10n.sharePostCopyAction,
        confirmIcon: Icons.copy,
      ),
    ),
  );
}
