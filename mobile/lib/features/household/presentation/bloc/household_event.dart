part of 'household_bloc.dart';

/// Base class for household events.
sealed class HouseholdEvent extends Equatable {
  const HouseholdEvent();

  @override
  List<Object?> get props => [];
}

/// Load all household members.
final class LoadMembers extends HouseholdEvent {
  const LoadMembers({this.activeOnly = true});

  final bool activeOnly;

  @override
  List<Object?> get props => [activeOnly];
}

/// Load archived members.
final class LoadArchivedMembers extends HouseholdEvent {
  const LoadArchivedMembers();
}

/// Create a new member.
final class CreateMember extends HouseholdEvent {
  const CreateMember(this.member);

  final HouseholdMember member;

  @override
  List<Object?> get props => [member];
}

/// Update an existing member.
final class UpdateMember extends HouseholdEvent {
  const UpdateMember(this.member);

  final HouseholdMember member;

  @override
  List<Object?> get props => [member];
}

/// Toggle member active status.
final class ToggleMemberActive extends HouseholdEvent {
  const ToggleMemberActive(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Archive a member (soft-delete).
final class ArchiveMember extends HouseholdEvent {
  const ArchiveMember(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Restore an archived member.
final class RestoreMember extends HouseholdEvent {
  const RestoreMember(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Permanently delete an archived member.
final class DeleteMemberPermanently extends HouseholdEvent {
  const DeleteMemberPermanently(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Check if a member can be archived.
final class CheckCanArchive extends HouseholdEvent {
  const CheckCanArchive(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
