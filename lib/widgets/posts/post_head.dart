import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/event/event_head.dart';
import '../../pages/view_gallery_page.dart';
import '../../utility/app_links.dart';
import '../../utility/image_orientation.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/post_head_media_layout.dart';
import '../media/cached_image_widget.dart';
import '../media/image_media_slot.dart';
import '../media/video_media_slot.dart';
import '../common/app_dialog.dart';

/// Relationship of a post relative to the currently viewed post.
/// Only used on [PostHead] in related-posts views — not the main bulletin.
enum PostRelationTag { parent, sibling, child }

class PostHead extends StatefulWidget {
  final EventHead thisHead;
  final VoidCallback updatePost;

  /// When set (related-posts tab only), shows a Parent / Sibling / Child badge.
  final PostRelationTag? relationTag;

  const PostHead({
    super.key,
    required this.thisHead,
    required this.updatePost,
    this.relationTag,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PostHeadState createState() => _PostHeadState();
}

class _PostHeadState extends State<PostHead>
    with SingleTickerProviderStateMixin {
  static const double _titleFontSize = 22, _subtitleFontSize = 15;
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM • HH:mm');

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final Map<String, Size> _mediaSizes = <String, Size>{};

  @override
  void initState() {
    super.initState();
    _probeMediaSizes();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(covariant PostHead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thisHead.id != widget.thisHead.id ||
        !_sameMedia(oldWidget.thisHead.media, widget.thisHead.media)) {
      _mediaSizes.clear();
      _probeMediaSizes();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              HapticFeedback.lightImpact();
              _animationController.forward();
            },
            onTapUp: (_) {
              _animationController.reverse();
              _onHeadTap(context);
            },
            onTapCancel: () {
              _animationController.reverse();
            },
            child: Material(
              elevation: 4,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildCardBody(
                      context,
                      theme,
                      colorScheme,
                      constraints.maxWidth,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double cardWidth,
  ) {
    final allMedia =
        widget.thisHead.hasMedia ? _getMedia() : const <Map<String, dynamic>>[];
    final media = allMedia.length <= 4
        ? allMedia
        : allMedia.take(4).toList(growable: false);
    final orientations = [
      for (final entry in media)
        PostHeadMediaLayout.orientationForEntry(
          entry: entry,
          intrinsic: _mediaSizes[entry['src'] as String?],
        ),
    ];
    final plan = PostHeadMediaLayout.plan(orientations);
    final width = cardWidth.isFinite && cardWidth > 0
        ? cardWidth
        : MediaQuery.sizeOf(context).width;
    final sideWidth = PostHeadMediaLayout.sideRailWidth(
      sideCount: plan.sideIndices.length,
      cardWidth: width,
    );
    final Size? singleBottomSize = plan.isSingleBottomFill
        ? _mediaSizes[media[plan.bottomIndices.first]['src'] as String?]
        : null;
    final bottomHeight = PostHeadMediaLayout.bottomBandHeight(
      plan: plan,
      orientations: orientations,
      cardWidth: width,
      singleIntrinsic: singleBottomSize,
    );
    final showLeadSpeaker =
        !widget.thisHead.hasMedia && widget.thisHead.hasLeadSpeakerPortrait;
    final textRightPad = plan.hasSide ? 12.0 : 16.0;
    final textBottomPad =
        plan.hasBottom ? 12.0 : (plan.hasSide || showLeadSpeaker ? 12.0 : 16.0);

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: plan.hasSide ? 4 : 8,
            top: 12,
          ),
          child: Row(
            children: [
              Expanded(child: _buildStatusRow(theme, colorScheme)),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _showPostInfo(context),
                tooltip: 'Post Info',
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, textRightPad, textBottomPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(theme, colorScheme),
              const SizedBox(height: 8),
              if (widget.thisHead.subtitle.isNotEmpty) ...[
                _buildSubtitle(theme, colorScheme),
                const SizedBox(height: 12),
              ],
              if (widget.thisHead.hasAttendanceCounts) ...[
                _buildAttendanceCounts(theme, colorScheme),
                const SizedBox(height: 12),
              ],
              if (widget.thisHead.hasEventDate)
                _buildWhenLine(theme, colorScheme),
            ],
          ),
        ),
        if (showLeadSpeaker) ...[
          _buildLeadSpeakerPortrait(theme, colorScheme),
          const SizedBox(height: 16),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: plan.hasSide ? PostHeadMediaLayout.sideMinHeight : 0,
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(right: plan.hasSide ? sideWidth : 0),
                child: textColumn,
              ),
              if (plan.hasSide)
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  width: sideWidth,
                  child: _buildMediaTiles(
                    indices: plan.sideIndices,
                    media: media,
                    context: context,
                    stacked: true,
                  ),
                ),
            ],
          ),
        ),
        if (plan.hasBottom)
          SizedBox(
            height: bottomHeight,
            width: double.infinity,
            child: _buildMediaTiles(
              indices: plan.bottomIndices,
              media: media,
              context: context,
              stacked: false,
            ),
          ),
      ],
    );
  }

  Widget _buildLeadSpeakerPortrait(ThemeData theme, ColorScheme colorScheme) {
    final imgSrc = widget.thisHead.leadSpeakerImgSrc;
    final name = widget.thisHead.leadSpeakerName ?? 'Lead speaker';
    final hasImage = imgSrc != null && imgSrc.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (hasImage)
              ClipOval(
                child: Image.network(
                  NetworkImageHelper.getImageUrl(imgSrc),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _leadSpeakerInitialsAvatar(theme, colorScheme, name),
                ),
              )
            else
              _leadSpeakerInitialsAvatar(theme, colorScheme, name),
            const SizedBox(height: 12),
            Text(
              name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Lead speaker',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leadSpeakerInitialsAvatar(
      ThemeData theme, ColorScheme colorScheme, String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty
        ? '?'
        : parts
            .take(2)
            .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
            .join();
    return CircleAvatar(
      radius: 60,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initials,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMediaTiles({
    required List<int> indices,
    required List<Map<String, dynamic>> media,
    required BuildContext context,
    required bool stacked,
  }) {
    if (indices.isEmpty) {
      return const SizedBox.shrink();
    }

    final Widget tiles;
    if (indices.length == 1) {
      tiles = _buildMediaSlot(media[indices.first], indices.first, context);
    } else if (indices.length == 2) {
      final first = _buildMediaSlot(media[indices[0]], indices[0], context);
      final second = _buildMediaSlot(media[indices[1]], indices[1], context);
      tiles = stacked
          ? Column(
              children: [
                Expanded(child: first),
                const SizedBox(height: PostHeadMediaLayout.mosaicGap),
                Expanded(child: second),
              ],
            )
          : Row(
              children: [
                Expanded(child: first),
                const SizedBox(width: PostHeadMediaLayout.mosaicGap),
                Expanded(child: second),
              ],
            );
    } else if (indices.length == 3) {
      tiles = Row(
        children: [
          Expanded(
            child: _buildMediaSlot(media[indices[0]], indices[0], context),
          ),
          const SizedBox(width: PostHeadMediaLayout.mosaicGap),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child:
                      _buildMediaSlot(media[indices[1]], indices[1], context),
                ),
                const SizedBox(height: PostHeadMediaLayout.mosaicGap),
                Expanded(
                  child:
                      _buildMediaSlot(media[indices[2]], indices[2], context),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      tiles = Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child:
                      _buildMediaSlot(media[indices[0]], indices[0], context),
                ),
                const SizedBox(height: PostHeadMediaLayout.mosaicGap),
                Expanded(
                  child:
                      _buildMediaSlot(media[indices[2]], indices[2], context),
                ),
              ],
            ),
          ),
          const SizedBox(width: PostHeadMediaLayout.mosaicGap),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child:
                      _buildMediaSlot(media[indices[1]], indices[1], context),
                ),
                const SizedBox(height: PostHeadMediaLayout.mosaicGap),
                Expanded(
                  child:
                      _buildMediaSlot(media[indices[3]], indices[3], context),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ColoredBox(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      child: tiles,
    );
  }

  Widget _buildStatusRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        if (widget.relationTag != null) ...[
          _buildRelationBadge(theme, colorScheme, widget.relationTag!),
          const SizedBox(width: 8),
        ],
        // Event Status Badge
        if (widget.thisHead.hasEventDate)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.thisHead.eventStatusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.thisHead.eventStatusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.thisHead.isUpcoming ? Icons.upcoming : Icons.history,
                  size: 12,
                  color: widget.thisHead.eventStatusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.thisHead.eventStatusText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.thisHead.eventStatusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        const Spacer(),

        // Location & Time Info
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              widget.thisHead.location,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelationBadge(
      ThemeData theme, ColorScheme colorScheme, PostRelationTag tag) {
    final (label, icon, color) = switch (tag) {
      PostRelationTag.parent => (
          'Parent',
          Icons.arrow_upward,
          colorScheme.primary
        ),
      PostRelationTag.sibling => (
          'Sibling',
          Icons.compare_arrows,
          colorScheme.tertiary
        ),
      PostRelationTag.child => (
          'Child',
          Icons.arrow_downward,
          colorScheme.secondary
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, ColorScheme colorScheme) {
    return Text(
      widget.thisHead.title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: _titleFontSize,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(ThemeData theme, ColorScheme colorScheme) {
    return Text(
      widget.thisHead.subtitle,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: _subtitleFontSize,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAttendanceCounts(ThemeData theme, ColorScheme colorScheme) {
    final parts = <String>[];
    if (widget.thisHead.interestedCount > 0) {
      parts.add('${widget.thisHead.interestedCount} interested');
    }
    if (widget.thisHead.attendeeCount > 0) {
      final attendeeWord = widget.thisHead.isRecent ? 'attended' : 'attending';
      parts.add('${widget.thisHead.attendeeCount} $attendeeWord');
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: theme.textTheme.labelMedium?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildWhenLine(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _eventDateFormat.format(widget.thisHead.eventDate!),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSlot(
      Map<String, dynamic> entry, int index, BuildContext context) {
    return entry['type']!.compareTo('img') == 0
        ? ImageMediaSlot(
            key: ValueKey('${widget.thisHead.id}-${entry['src']}'),
            mediaEntry: entry,
            onTap: () => _onMediaTap(index, context),
            postID: widget.thisHead.id,
          )
        : VideoMediaSlot(
            mediaEntry: entry,
            postId: widget.thisHead.id,
            onTap: () => _onMediaTap(index, context),
          );
  }

  // * Helper Methods

  List<Map<String, dynamic>> _getMedia() {
    if (kIsWeb) {
      return widget.thisHead.media.where((e) => e['type'] == 'img').toList();
    }
    return widget.thisHead.media;
  }

  bool _sameMedia(
    final List<Map<String, dynamic>> a,
    final List<Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i]['src'] != b[i]['src'] || a[i]['type'] != b[i]['type']) {
        return false;
      }
    }
    return true;
  }

  Future<void> _probeMediaSizes() async {
    var changed = false;
    for (final entry in _getMedia().take(4)) {
      if (entry['type'] != 'img') {
        continue;
      }
      final src = entry['src'] as String? ?? '';
      if (src.isEmpty || _mediaSizes.containsKey(src)) {
        continue;
      }
      try {
        final bytes = await CachedImageLoader.fetchBytes(src);
        final size = await ImageOrientationHelper.decodeSize(bytes);
        if (!mounted || size == null) {
          continue;
        }
        _mediaSizes[src] = size;
        changed = true;
      } catch (error) {
        debugPrint('PostHead: failed to probe $src ($error)');
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 5) {
      return "a few seconds ago";
    } else if (difference.inMinutes < 5) {
      return "a few minutes ago";
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return "$minutes ${(minutes == 1) ? 'minute' : 'minutes'} ago";
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return "$hours ${(hours == 1) ? 'hour' : 'hours'} ago";
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return "$days ${(days == 1) ? 'day' : 'days'} ago";
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return "$weeks ${(weeks == 1) ? 'week' : 'weeks'} ago";
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return "$months ${(months == 1) ? 'month' : 'months'} ago";
    } else {
      final years = (difference.inDays / 365).floor();
      return "$years ${(years == 1) ? 'year' : 'years'} ago";
    }
  }

  // * Event Handlers

  void _onHeadTap(BuildContext context) {
    AppLinks.openPost(
      context,
      id: widget.thisHead.id,
      extra: widget.thisHead,
    ).then((_) => widget.updatePost());
  }

  void _onMediaTap(int index, BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewGalleryPage(
          media: widget.thisHead.media,
          initialIndex: index,
          postId: widget.thisHead.id,
        ),
      ),
    );
  }

  void _showPostInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        icon: Icons.info_outline,
        title: 'Post Details',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Post ID', widget.thisHead.id, context),
            const SizedBox(height: 8),
            _buildInfoRow('Location', widget.thisHead.location, context),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Media Count', '${widget.thisHead.mediaCount}', context),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Last Updated',
              _timeAgo(widget.thisHead.recentDate),
              context,
            ),
            if (widget.thisHead.hasEventDate) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                  'Event Status', widget.thisHead.eventStatusText, context),
            ],
          ],
        ),
        actions: AppDialogActions(
          onConfirm: () => Navigator.pop(context),
          confirmLabel: 'Close',
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}
