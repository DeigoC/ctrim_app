import 'package:flutter/material.dart';

import '../../utility/people_directory_sections.dart';

/// One wide-directory row of fixed-width cards.
///
/// A short last row keeps the grid's card width. [spacedBelow] is the grid's
/// main-axis gap, and is omitted before a letter or surname heading.
class PeopleDirectoryBand extends StatelessWidget {
  const PeopleDirectoryBand({
    super.key,
    required this.crossAxisExtent,
    required this.mainAxisExtent,
    required this.spacedBelow,
    required this.children,
  });

  final double crossAxisExtent;
  final double mainAxisExtent;
  final bool spacedBelow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final childWidth =
        PeopleDirectoryGrid.childCrossAxisExtent(crossAxisExtent);
    return Padding(
      padding: EdgeInsets.only(
        bottom: spacedBelow ? PeopleDirectoryGrid.mainAxisSpacing : 0,
      ),
      child: SizedBox(
        height: mainAxisExtent,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const SizedBox(width: PeopleDirectoryGrid.crossAxisSpacing),
              SizedBox(
                width: childWidth,
                height: mainAxisExtent,
                child: children[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
