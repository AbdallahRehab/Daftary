import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../domain/entities/finance_entry_type.dart';

/// One curated icon choice: a stable string [key] persisted in
/// `FinanceCategories.icon`, paired with the glyph it renders as.
class CategoryIconOption {
  const CategoryIconOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}

/// Maps the string keys stored in `FinanceCategories.icon` to Material
/// glyphs (research.md Decision 10).
///
/// A category persists a key, never an `IconData` codepoint and never a hex
/// color: a codepoint would break the moment Flutter's icon font changed,
/// and a persisted color would bypass the theme and go unreadable in dark
/// mode (constitution Principle XV). Color comes from the theme at render
/// time via [colorFor], not from the database.
class CategoryIconRegistry {
  const CategoryIconRegistry._();

  /// The fallback for a key this registry does not know — an icon written by
  /// a newer build, say. Rendering a generic glyph keeps the row readable
  /// rather than crashing or leaving a hole.
  static const IconData fallbackIcon = Icons.label_outline;

  /// The key every "no better choice" path uses, and the one the seeded
  /// "Other" expense category carries.
  static const String fallbackKey = 'other';

  static const Map<String, IconData> _icons = {
    // Expense — the 16 seeded keys first, in seed order.
    'rent': Icons.home_outlined,
    'electricity': Icons.bolt_outlined,
    'water': Icons.water_drop_outlined,
    'internet': Icons.wifi,
    'phone': Icons.smartphone_outlined,
    'groceries': Icons.local_grocery_store_outlined,
    'transportation': Icons.directions_bus_outlined,
    'fuel': Icons.local_gas_station_outlined,
    'medical': Icons.medical_services_outlined,
    'education': Icons.school_outlined,
    'entertainment': Icons.movie_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'restaurants': Icons.restaurant_outlined,
    'subscriptions': Icons.subscriptions_outlined,
    'family': Icons.family_restroom_outlined,
    fallbackKey: fallbackIcon,
    // Income — the 6 seeded keys.
    'salary': Icons.payments_outlined,
    'freelance': Icons.laptop_mac_outlined,
    'business': Icons.storefront_outlined,
    'bonus': Icons.emoji_events_outlined,
    'gift': Icons.card_giftcard_outlined,
    'other_income': Icons.savings_outlined,
    // Extra choices offered to custom categories only.
    'travel': Icons.flight_takeoff_outlined,
    'fitness': Icons.fitness_center_outlined,
    'pets': Icons.pets_outlined,
    'charity': Icons.volunteer_activism_outlined,
    'insurance': Icons.shield_outlined,
    'taxes': Icons.receipt_long_outlined,
    'repairs': Icons.build_outlined,
    'childcare': Icons.child_care_outlined,
    'beauty': Icons.content_cut_outlined,
    'investment': Icons.trending_up,
    'rental_income': Icons.apartment_outlined,
    'refund': Icons.assignment_return_outlined,
  };

  /// The glyph for [key], or [fallbackIcon] if the key is unknown.
  static IconData iconFor(String key) => _icons[key] ?? fallbackIcon;

  static bool contains(String key) => _icons.containsKey(key);

  /// Every key, in declaration order — what the icon picker grid renders.
  static List<String> get allKeys => _icons.keys.toList(growable: false);

  static List<CategoryIconOption> get allOptions => [
    for (final entry in _icons.entries)
      CategoryIconOption(key: entry.key, icon: entry.value),
  ];

  /// The theme color a category's icon renders in, keyed by the category's
  /// direction rather than by the individual category.
  ///
  /// Resolved from `AppFinanceColors` through the current [context], so the
  /// same stored key reads correctly in light and dark mode — which is
  /// exactly what persisting a per-category hex color would have prevented.
  static Color colorFor(BuildContext context, CategoryType type) {
    final financeColors = context.financeColors;
    return type == CategoryType.income
        ? financeColors.positive
        : financeColors.negative;
  }

  /// The tinted background the icon sits on, paired with [colorFor].
  static Color surfaceColorFor(BuildContext context, CategoryType type) {
    final financeColors = context.financeColors;
    return type == CategoryType.income
        ? financeColors.positiveSurface
        : financeColors.negativeSurface;
  }
}
