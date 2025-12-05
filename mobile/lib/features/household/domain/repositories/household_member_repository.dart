import '../entities/household_member.dart';

/// Repository interface for household members.
///
/// Uses soft-delete via archive/restore pattern.
abstract class HouseholdMemberRepository {
  /// Gets all active (non-archived) household members.
  Future<List<HouseholdMember>> getMembers({bool activeOnly = true});

  /// Gets all archived members.
  Future<List<HouseholdMember>> getArchivedMembers();

  /// Gets a single member by ID (including archived).
  Future<HouseholdMember?> getMemberById(int id);

  /// Creates a new member.
  Future<HouseholdMember> createMember(HouseholdMember member);

  /// Updates an existing member.
  Future<HouseholdMember> updateMember(HouseholdMember member);

  /// Toggles member active status.
  Future<HouseholdMember> toggleActive(int id);

  /// Archives a member (soft-delete).
  Future<bool> archiveMember(int id);

  /// Restores an archived member.
  Future<HouseholdMember> restoreMember(int id);

  /// Permanently deletes an archived member.
  Future<bool> deleteMemberPermanently(int id);

  /// Checks if a member can be archived (no pending transactions).
  Future<bool> canArchiveMember(int id);
}
