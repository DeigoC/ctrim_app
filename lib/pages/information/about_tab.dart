import 'package:flutter/material.dart';

import '../../utility/responsive_layout.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/information/info_section_card.dart';

class InformationAboutTab extends StatelessWidget {
  const InformationAboutTab({super.key});

  static const String _mission =
      'https://drive.google.com/uc?id=1RWa_4vx6vo1dXCP3SNc6WglxYTBoRY9T';
  static const String _vision =
      'https://drive.google.com/uc?id=1J7ZOPtjkb6iietVPyOdFMMIU29XwfjUX';
  static const String _community =
      'https://drive.google.com/uc?id=1bxbAq9RDwUPcf8yAzOAu6Ah-OG3YC1BI';
  static const String _coreValues =
      'https://drive.google.com/uc?id=1v4_0sABmlwLCvahonbVMs5GOLO8iWDzX';

  @override
  Widget build(BuildContext context) {
    const String matthewVerse =
        '"Therefore go and make disciples of all nations, baptizing them in the '
        'name of the Father and of the Son and of the Holy Spirit, and '
        'teaching them to obey everything I have commanded you. And '
        'surely I am with you always, to the very end of the age."';
    const String visionParagraph =
        'Our vision is to become like the early Church in the Book of Acts, effective '
        'and strategic in disciple making. Effective and strategic in harnessing the power of The Holy Spirit, causing '
        'them to multiply rapidly and having the power to turn the world upside down for the Glory of God.';

    const List<String> coreValues = [
      'I Am a True Disciple. Christ-likeness and Multiplying Ministry',
      'Caught by the Vision. Understand, Live and Transmit the Vision',
      'Committed to Cell Life. Evangelism, Leadership Development and Multiplication',
      'Passionate Spirituality Devotional Life, Prayer, Fasting and Holiness',
      'Submission to Authority Love, Honour and Respect My Leaders',
      'Commitment to Time Management and Invest My Time for the Kingdom of God',
      'Lifelong Relationship. Accountable and Responsible',
      'I Love Equipping and Training. Training is My Happy Hour',
      'I Am a Leader of 7 Disciples. I Am Born to Multiply',
      'Accomplishing Church Goal Setting. Support, Help and Fulfil the Goals',
      'I Want to See My Church Grow. I Pray, Work and Pay',
      'The Importance of Young People. I Will Prepare the Next Generation',
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final maxWidth = ResponsiveLayout.maxContentWidth(screenWidth);
        final horizontalPadding =
            screenWidth < ResponsiveLayout.compact ? 16.0 : 32.0;
        final isWideScreen = screenWidth >= ResponsiveLayout.tablet;

        return SingleChildScrollView(
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.church,
                            size: 48, color: colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Christ the Redeemer International Ministries',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Dedicated and committed to making true disciples who will passionately advance the Kingdom of God.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedImageWidget(
                      imageUrl: _community,
                      height: isWideScreen ? 250 : 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isWideScreen)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildMissionSection(
                            theme: theme,
                            colorScheme: colorScheme,
                            matthewVerse: matthewVerse,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildVisionSection(
                            theme: theme,
                            colorScheme: colorScheme,
                            visionParagraph: visionParagraph,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildMissionSection(
                          theme: theme,
                          colorScheme: colorScheme,
                          matthewVerse: matthewVerse,
                        ),
                        const SizedBox(height: 20),
                        _buildVisionSection(
                          theme: theme,
                          colorScheme: colorScheme,
                          visionParagraph: visionParagraph,
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  InfoSectionCard(
                    icon: Icons.favorite,
                    title: 'OUR CORE VALUES',
                    subtitle:
                        'The foundation of what is really important to us',
                    content: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Core values are the foundation of what is really important to us. It gives us CLARITY about who we are and what we stand for. It gives us the ability to STAY FOCUS on what matters most. It gives us UNITY, MATURITY and HEALTH to grow and multiply.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedImageWidget(
                            imageUrl: _coreValues,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...coreValues.asMap().entries.map((entry) {
                          final index = entry.key;
                          final value = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    value,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionSection({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String matthewVerse,
  }) {
    return InfoSectionCard(
      icon: Icons.flag,
      title: 'OUR MISSION',
      subtitle: 'To Win Souls and Make Disciples.',
      content: Column(
        children: [
          Text(
            'Matthew 28:19-20',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Text(
              matthewVerse,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedImageWidget(
              imageUrl: _mission,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisionSection({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String visionParagraph,
  }) {
    return InfoSectionCard(
      icon: Icons.visibility,
      title: 'OUR VISION',
      subtitle: 'To become an effective and strategic disciple-making church.',
      content: Column(
        children: [
          Text(
            visionParagraph,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedImageWidget(
              imageUrl: _vision,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
