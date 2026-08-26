import 'package:flutter/material.dart';

/// One selectable row in [SelectCatalogItemsPage].
class CatalogPickerEntry {
  const CatalogPickerEntry({
    required this.id,
    required this.label,
    this.subtitle,
    this.accentColor,
    this.icon = Icons.label_outline,
    this.location,
    this.isActive = true,
    this.isNotifiable = false,
    this.displayOrder = 0,
  });

  final String id;
  final String label;
  final String? subtitle;
  final Color? accentColor;
  final IconData icon;
  final String? location;
  final bool isActive;
  final bool isNotifiable;
  final int displayOrder;
}
