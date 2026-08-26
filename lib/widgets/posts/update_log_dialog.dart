import 'package:flutter/material.dart';

import '../common/app_dialog.dart';

/// Material 3 dialog that collects a short update note before save.
///
/// By default pops with the trimmed log (or `null` if cancelled). Pass [onSave]
/// when the caller needs to keep this route open (e.g. nested confirm/progress).
class UpdateLogDialog extends StatefulWidget {
  const UpdateLogDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.hintText = 'e.g. Added new images',
    this.fieldLabel = 'Update note',
    this.confirmLabel = 'Save',
    this.confirmIcon = Icons.save_outlined,
    this.bannerIcon = Icons.notifications_outlined,
    this.onSave,
  });

  final String title;
  final String subtitle;
  final String hintText;
  final String fieldLabel;
  final String confirmLabel;
  final IconData confirmIcon;
  final IconData bannerIcon;

  /// If set, called with the trimmed log instead of popping.
  final Future<void> Function(String log)? onSave;

  @override
  State<UpdateLogDialog> createState() => _UpdateLogDialogState();
}

class _UpdateLogDialogState extends State<UpdateLogDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _canSave = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Icons.edit_note_outlined,
      title: widget.title,
      banner: AppDialogBanner(
        icon: widget.bannerIcon,
        message: widget.subtitle,
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 128,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onChanged: _onTextChange,
        onSubmitted: (_) {
          if (_canSave) _confirm();
        },
        decoration: AppDialog.inputDecoration(
          label: widget.fieldLabel,
          hint: widget.hintText,
          maxLines: 3,
        ),
      ),
      actions: AppDialogActions(
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: _confirm,
        confirmEnabled: _canSave,
        confirmLabel: widget.confirmLabel,
        confirmIcon: widget.confirmIcon,
      ),
    );
  }

  void _onTextChange(String value) {
    final hasText = value.trim().isNotEmpty;
    if (_canSave != hasText) {
      setState(() => _canSave = hasText);
    }
  }

  Future<void> _confirm() async {
    final log = _controller.text.trim();
    if (log.isEmpty) return;

    final onSave = widget.onSave;
    if (onSave == null) {
      Navigator.of(context).pop(log);
      return;
    }
    await onSave(log);
  }
}
