import 'package:flutter/material.dart';

/// Collects a short update note before saving a post template (mirrors post [EventLogDialog] input).
class TemplateLogDialog extends StatefulWidget {
  const TemplateLogDialog({super.key});

  @override
  State<TemplateLogDialog> createState() => _TemplateLogDialogState();
}

class _TemplateLogDialogState extends State<TemplateLogDialog> {
  final TextEditingController _tecLog = TextEditingController();
  bool _canSave = false;

  @override
  void dispose() {
    _tecLog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What changed?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tecLog,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Updated cover pool',
                  label: Text('Update Log'),
                ),
                maxLength: 128,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _onTextChange,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  TextButton.icon(
                    onPressed: _canSave ? () => Navigator.of(context).pop(_tecLog.text.trim()) : null,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTextChange(String newString) {
    final hasText = newString.trim().isNotEmpty;
    if (_canSave != hasText) {
      setState(() => _canSave = hasText);
    }
  }
}
