part of 'household_bloc.dart';

/// Household loading status.
enum HouseholdStatus { initial, loading, success, failure }

/// State for the household bloc.
final class HouseholdState extends Equatable {
  const HouseholdState({
    this.status = HouseholdStatus.initial,
    this.members = const [],
    this.archivedMembers = const [],
    this.error,
    this.canArchiveMember = true,
    this.showingArchived = false,
  });

  /// Current loading status.
  final HouseholdStatus status;

  /// List of active household members.
  final List<HouseholdMember> members;

  /// List of archived members.
  final List<HouseholdMember> archivedMembers;

  /// Error message if status is failure.
  final String? error;

  /// Whether the currently checked member can be archived.
  final bool canArchiveMember;

  /// Whether currently showing archived members.
  final bool showingArchived;

  /// Creates a copy of this state with the given fields replaced.
  HouseholdState copyWith({
    HouseholdStatus? status,
    List<HouseholdMember>? members,
    List<HouseholdMember>? archivedMembers,
    String? error,
    bool? canArchiveMember,
    bool? showingArchived,
  }) {
    return HouseholdState(
      status: status ?? this.status,
      members: members ?? this.members,
      archivedMembers: archivedMembers ?? this.archivedMembers,
      error: error ?? this.error,
      canArchiveMember: canArchiveMember ?? this.canArchiveMember,
      showingArchived: showingArchived ?? this.showingArchived,
    );
  }

  @override
  List<Object?> get props => [
        status,
        members,
        archivedMembers,
        error,
        canArchiveMember,
        showingArchived,
      ];
}
