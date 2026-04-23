import 'package:flutter/material.dart';

class ItemCategory {
  final String id;
  final String label;
  final IconData icon;
  const ItemCategory(this.id, this.label, this.icon);
}

const kCategories = <ItemCategory>[
  ItemCategory('kitchen', 'Kitchen', Icons.kitchen),
  ItemCategory('garden', 'Garden', Icons.grass),
  ItemCategory('cleaning', 'Cleaning', Icons.cleaning_services),
  ItemCategory('tools', 'Tools', Icons.build),
  ItemCategory('electronics', 'Electronics', Icons.devices),
  ItemCategory('other', 'Other', Icons.category),
];

ItemCategory categoryById(String id) =>
    kCategories.firstWhere((c) => c.id == id, orElse: () => kCategories.last);

const kDefaultRadiusKm = 10.0;
const kMaxRadiusKm = 50.0;
