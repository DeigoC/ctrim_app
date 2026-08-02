import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/event/event_head.dart';
import '../../pages/events/view_event_page.dart';
import '../../pages/view_gallery_page.dart';
import '../../utility/network_image_helper.dart';
import '../media/image_media_slot.dart';
import '../media/video_media_slot.dart';

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

class _PostHeadState extends State<PostHead> with SingleTickerProviderStateMixin {
  static const double _titleFontSize = 22, _subtitleFontSize = 15;
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM • HH:mm');

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with info button
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8, top: 12),
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

                    // Content Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          _buildActionRow(theme, colorScheme),
                        ],
                      ),
                    ),

                    // Media Section
                    if (widget.thisHead.hasMedia) ...[
                      const SizedBox(height: 12),
                      _buildMediaGrid(context),
                    ] else if (widget.thisHead.hasLeadSpeakerPortrait) ...[
                      const SizedBox(height: 12),
                      _buildLeadSpeakerPortrait(theme, colorScheme),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
                  errorBuilder: (_, __, ___) => _leadSpeakerInitialsAvatar(theme, colorScheme, name),
                ),
              )
            else
              _leadSpeakerInitialsAvatar(theme, colorScheme, name),
            const SizedBox(height: 12),
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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

  Widget _leadSpeakerInitialsAvatar(ThemeData theme, ColorScheme colorScheme, String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
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

  Widget _buildMediaGrid(BuildContext context) {
    final List<Map<String, dynamic>> media = _getMedia();

    if (media.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaLayout(media, context),
      ),
    );
  }

  Widget _buildMediaLayout(List<Map<String, dynamic>> media, BuildContext context) {
    if (media.length == 1) {
      return _buildMediaSlot(media.first, 0, context);
    } else if (media.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildMediaSlot(media[0], 0, context)),
          const SizedBox(width: 2),
          Expanded(child: _buildMediaSlot(media[1], 1, context)),
        ],
      );
    } else if (media.length == 3) {
      return Row(
        children: [
          Expanded(child: _buildMediaSlot(media[0], 0, context)),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildMediaSlot(media[1], 1, context)),
                const SizedBox(height: 2),
                Expanded(child: _buildMediaSlot(media[2], 2, context)),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4+ media items
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildMediaSlot(media[0], 0, context)),
                const SizedBox(height: 2),
                Expanded(child: _buildMediaSlot(media[2], 2, context)),
              ],
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildMediaSlot(media[1], 1, context)),
                const SizedBox(height: 2),
                Expanded(child: _buildMediaSlot(media[3], 3, context)),
              ],
            ),
          ),
        ],
      );
    }
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

  Widget _buildRelationBadge(ThemeData theme, ColorScheme colorScheme, PostRelationTag tag) {
    final (label, icon, color) = switch (tag) {
      PostRelationTag.parent => ('Parent', Icons.arrow_upward, colorScheme.primary),
      PostRelationTag.sibling => ('Sibling', Icons.compare_arrows, colorScheme.tertiary),
      PostRelationTag.child => ('Child', Icons.arrow_downward, colorScheme.secondary),
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

  Widget _buildActionRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Event Date/Time
        if (widget.thisHead.hasEventDate) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _eventDateFormat.format(widget.thisHead.eventDate!),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Media Count (if any)
        if (widget.thisHead.hasMedia)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.thisHead.imageCount > 0 ? Icons.image : Icons.play_circle,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.thisHead.mediaCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        const Spacer(),

        // Last Updated
        Text(
          'Updated ${_timeAgo(widget.thisHead.recentDate)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSlot(Map<String, dynamic> entry, int index, BuildContext context) {
    return entry['type']!.compareTo('img') == 0
        ? ImageMediaSlot(
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: widget.thisHead)),
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Post Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Post ID', widget.thisHead.id, context),
            const SizedBox(height: 8),
            _buildInfoRow('Location', widget.thisHead.location, context),
            const SizedBox(height: 8),
            _buildInfoRow('Media Count', '${widget.thisHead.mediaCount}', context),
            if (widget.thisHead.hasEventDate) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Event Status', widget.thisHead.eventStatusText, context),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
