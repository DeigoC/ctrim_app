import 'package:flutter/material.dart';

import '../../utility/event_context.dart';
import '../quill_editor_wrapper.dart';

class ViewPostBody extends StatelessWidget {
  const ViewPostBody(
      {super.key,
      required this.eventContext,
      required this.updateBody,
      required this.currentUID});
  final EventContext eventContext;
  final Function updateBody;
  final String currentUID;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                elevation: 1,
                margin: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.article_outlined,
                              size: 18, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            'Post Content',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    QuillViewerWidget(
                      key: ValueKey(eventContext.encodedBody),
                      jsonContent: eventContext.body,
                      padding: const EdgeInsets.all(16.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
