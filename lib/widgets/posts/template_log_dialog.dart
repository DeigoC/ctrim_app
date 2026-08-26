import 'package:flutter/material.dart';

import 'update_log_dialog.dart';

/// Collects a short update note before saving a post template (mirrors post [EventLogDialog] input).
class TemplateLogDialog extends StatelessWidget {
  const TemplateLogDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const UpdateLogDialog(
      title: 'Save template',
      subtitle: 'Add a short note for the template change history.',
      hintText: 'e.g. Updated cover pool',
      confirmLabel: 'Save',
      bannerIcon: Icons.history_outlined,
    );
  }
}
