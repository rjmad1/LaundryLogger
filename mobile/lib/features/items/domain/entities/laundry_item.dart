import 'package:equatable/equatable.dart';

/// Represents a laundry item that can be sent for ironing.
///
/// Each item has a [name], [defaultRate], and optional [category].
/// Items can be marked as [isFavorite] for quick access.
/// Items use soft-delete via [isArchived] instead of hard deletion.
class LaundryItem extends Equatable {
  /// Creates a new laundry item.
  const LaundryItem({
    required this.name,
    required this.defaultRate,
    this.id,
    this.category,
    this.isFavorite = false,
    this.isArchived = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for the item.
  final int? id;

  /// The display name of the item (e.g., "Shirt", "Pants").
  final String name;

  /// The default cost per item in local currency.
  final double defaultRate;

  /// Optional category for grouping items (e.g., "Clothing", "Bedding").
  final String? category;

  /// Whether this item is marked as a favorite for quick access.
  final bool isFavorite;

  /// Whether this item is archived (soft-deleted).
  final bool isArchived;

  /// Sort order for custom ordering in lists.
  final int sortOrder;

  /// When the item was created.
  final DateTime? createdAt;

  /// When the item was last updated.
  final DateTime? updatedAt;

  /// Creates a copy of this item with the given fields replaced.
  LaundryItem copyWith({
    int? id,
    String? name,
    double? defaultRate,
    String? category,
    bool? isFavorite,
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LaundryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultRate: defaultRate ?? this.defaultRate,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        defaultRate,
        category,
        isFavorite,
        isArchived,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}
