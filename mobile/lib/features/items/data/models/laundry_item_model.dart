import '../../domain/entities/laundry_item.dart';

/// Data model for LaundryItem with JSON/Map serialization.
class LaundryItemModel extends LaundryItem {
  /// Creates a new LaundryItemModel.
  const LaundryItemModel({
    required super.name,
    required super.defaultRate,
    super.id,
    super.category,
    super.isFavorite = false,
    super.isArchived = false,
    super.sortOrder = 0,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a LaundryItemModel from a Map (database row).
  factory LaundryItemModel.fromMap(Map<String, dynamic> map) {
    return LaundryItemModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      defaultRate: (map['default_rate'] as num).toDouble(),
      category: map['category'] as String?,
      isFavorite: (map['is_favorite'] as int) == 1,
      isArchived: (map['is_archived'] as int?) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Creates a LaundryItemModel from a domain entity.
  factory LaundryItemModel.fromEntity(LaundryItem item) {
    return LaundryItemModel(
      id: item.id,
      name: item.name,
      defaultRate: item.defaultRate,
      category: item.category,
      isFavorite: item.isFavorite,
      isArchived: item.isArchived,
      sortOrder: item.sortOrder,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  /// Converts this model to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'default_rate': defaultRate,
      'category': category,
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Converts this model to a Map for insertion (without id).
  Map<String, dynamic> toInsertMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'name': name,
      'default_rate': defaultRate,
      'category': category,
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Converts this model to a Map for update (with updated_at).
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'default_rate': defaultRate,
      'category': category,
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'sort_order': sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Converts this model to a domain entity.
  LaundryItem toEntity() {
    return LaundryItem(
      id: id,
      name: name,
      defaultRate: defaultRate,
      category: category,
      isFavorite: isFavorite,
      isArchived: isArchived,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
