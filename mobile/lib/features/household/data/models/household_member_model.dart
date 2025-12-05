import '../../domain/entities/household_member.dart';

/// Data model for HouseholdMember with JSON/Map serialization.
class HouseholdMemberModel extends HouseholdMember {
  /// Creates a new HouseholdMemberModel.
  const HouseholdMemberModel({
    required super.name,
    super.id,
    super.color,
    super.isActive = true,
    super.isArchived = false,
    super.createdAt,
  });

  /// Creates a HouseholdMemberModel from a Map (database row).
  factory HouseholdMemberModel.fromMap(Map<String, dynamic> map) {
    return HouseholdMemberModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as String?,
      isActive: (map['is_active'] as int) == 1,
      isArchived: (map['is_archived'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Creates a HouseholdMemberModel from a domain entity.
  factory HouseholdMemberModel.fromEntity(HouseholdMember member) {
    return HouseholdMemberModel(
      id: member.id,
      name: member.name,
      color: member.color,
      isActive: member.isActive,
      isArchived: member.isArchived,
      createdAt: member.createdAt,
    );
  }

  /// Converts this model to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Converts this model to a Map for insertion (without id).
  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Converts this model to a Map for update.
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  /// Converts this model to a domain entity.
  HouseholdMember toEntity() {
    return HouseholdMember(
      id: id,
      name: name,
      color: color,
      isActive: isActive,
      isArchived: isArchived,
      createdAt: createdAt,
    );
  }
}
