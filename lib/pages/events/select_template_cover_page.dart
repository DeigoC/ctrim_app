import 'package:flutter/material.dart';

import '../../models/post_template.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/post_template_loader.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/load_progress_body.dart';

/// Pick a cover image from templates that have a key-graphic (cover) pool.
///
/// Returns a media map (`src`, `type`, `title`, `thumbnailSrc`) or null if cancelled.
class SelectTemplateCoverPage extends StatefulWidget {
  const SelectTemplateCoverPage({
    super.key,
    this.preferredTitle,
    this.preferredLocation,
  });

  /// Post title used to suggest matching templates (e.g. bulk titles start with template title).
  final String? preferredTitle;

  final String? preferredLocation;

  @override
  State<SelectTemplateCoverPage> createState() => _SelectTemplateCoverPageState();
}

class _SelectTemplateCoverPageState extends State<SelectTemplateCoverPage> {
  List<PostTemplate> _templates = const [];
  bool _loading = true;
  Object? _loadError;
  String _status = 'Loading templates…';
  int _completed = 0;
  int _total = 4;
  String? _expandedTemplateId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _status = 'Loading templates…';
      _completed = 0;
      _total = 4;
    });

    try {
      final templates = await PostTemplateLoader.load(
        onProgress: ({required completed, required total, required message}) {
          if (!mounted) return;
          setState(() {
            _completed = completed;
            _total = total;
            _status = message;
          });
        },
      );
      if (!mounted) return;

      final withPools = templates.where((t) => t.keyGraphicPool.isNotEmpty).toList()
        ..sort((a, b) {
          final aScore = _relevanceScore(a);
          final bScore = _relevanceScore(b);
          if (aScore != bScore) return bScore.compareTo(aScore);
          return a.title.compareTo(b.title);
        });

      setState(() {
        _templates = withPools;
        _loading = false;
        if (withPools.isNotEmpty && _relevanceScore(withPools.first) > 0) {
          _expandedTemplateId = withPools.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  int _relevanceScore(PostTemplate template) {
    var score = 0;
    final preferredTitle = widget.preferredTitle?.trim();
    if (preferredTitle != null && preferredTitle.isNotEmpty) {
      final title = template.title.trim();
      if (title.isNotEmpty) {
        if (preferredTitle == title || preferredTitle.startsWith('$title ') || preferredTitle.startsWith('$title–') || preferredTitle.startsWith('$title –') || preferredTitle.startsWith('$title -')) {
          score += 10;
        } else if (preferredTitle.toLowerCase().contains(title.toLowerCase())) {
          score += 4;
        }
      }
    }
    final preferredLocation = widget.preferredLocation?.trim();
    if (preferredLocation != null &&
        preferredLocation.isNotEmpty &&
        template.location.trim().toLowerCase() == preferredLocation.toLowerCase()) {
      score += 2;
    }
    return score;
  }

  void _onSelect(Map<String, dynamic> item) {
    Navigator.of(context).pop(Map<String, dynamic>.from(item));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose cover image'),
        backgroundColor: colorScheme.surface,
      ),
      body: _buildBody(colorScheme, horizontalPadding),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, double horizontalPadding) {
    if (_loading) {
      return LoadProgressBody(
        message: _status,
        completedSteps: _completed,
        totalSteps: _total,
      );
    }

    if (_loadError != null) {
      return LoadProgressBody(
        message: 'Could not load templates',
        completedSteps: 0,
        totalSteps: 1,
        error: _loadError,
        errorTitle: 'Could not load templates',
        onRetry: _load,
      );
    }

    if (_templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No templates have a cover image pool yet.\nAdd covers under Edit Template → Media → Cover Image Pool.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 24),
      itemCount: _templates.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Pick a cover from a template pool. Suggested matches for this post are listed first.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        final template = _templates[index - 1];
        final suggested = _relevanceScore(template) > 0;
        final expanded = _expandedTemplateId == template.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(template.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [
                    if (suggested) 'Suggested for this post',
                    '${template.keyGraphicPool.length} cover${template.keyGraphicPool.length == 1 ? '' : 's'}',
                    if (template.location.isNotEmpty) template.location,
                  ].join(' · '),
                ),
                trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                onTap: () {
                  setState(() {
                    _expandedTemplateId = expanded ? null : template.id;
                  });
                },
              ),
              if (expanded)
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: template.keyGraphicPool.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, poolIndex) {
                      final item = template.keyGraphicPool[poolIndex];
                      return _CoverTile(
                        item: item,
                        onTap: () => _onSelect(item),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CoverTile extends StatelessWidget {
  const _CoverTile({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVideo = item['type'] == 'vid';
    final thumbnailSrc = item['thumbnailSrc'] as String?;
    final src = (item['src'] as String?) ?? '';
    final displaySrc = (isVideo ? thumbnailSrc : src)?.trim();
    final imageUrl =
        displaySrc != null && displaySrc.isNotEmpty ? NetworkImageHelper.getImageUrl(displaySrc) : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        width: 112,
        height: 100,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Icon(
                  isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
              if (isVideo)
                const Positioned(
                  right: 6,
                  bottom: 6,
                  child: Icon(Icons.play_circle_fill, color: Colors.white, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
