import 'package:flutter/material.dart';

class ImageMediaSlot extends StatelessWidget {
  const ImageMediaSlot({super.key, required this.mediaEntry, required this.onTap, required this.heroPrefix});
  final Map<String, String> mediaEntry;
  final Function()? onTap;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Hero(
            tag: heroPrefix + mediaEntry['src']!,
            child: Image.network(
              mediaEntry['src']!,
              fit: BoxFit.cover,
            )));
  }
}
