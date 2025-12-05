import 'package:equatable/equatable.dart';

/// Represents a household member for tagging laundry items.
///
/// Members use soft-delete via [isArchived] instead of hard deletion.
class HouseholdMember extends Equatable {
  /// Creates a new household member.
  const HouseholdMember({
    required this.name,
    this.id,
    this.color,
    this.isActive = true,
    this.isArchived = false,
    this.createdAt,
  });

  /// Unique identifier for the member.
  final int? id;

  /// Display name of the member.
  final String name;

  /// Color code for visual identification (hex string).
  final String? color;

  /// Whether the member is active.
  final bool isActive;

  /// Whether the member is archived (soft-deleted).
  final bool isArchived;

  /// When the member was added.
  final DateTime? createdAt;

  /// Creates a copy of this member with the given fields replaced.
  HouseholdMember copyWith({
    int? id,
    String? name,
    String? color,
    bool? isActive,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return HouseholdMember(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, color, isActive, isArchived, createdAt];
}
