import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/household_member.dart';
import '../../domain/repositories/household_member_repository.dart';

part 'household_event.dart';
part 'household_state.dart';

/// BLoC for managing household members.
class HouseholdBloc extends Bloc<HouseholdEvent, HouseholdState> {
  /// Creates a new HouseholdBloc.
  HouseholdBloc({required HouseholdMemberRepository memberRepository})
      : _memberRepository = memberRepository,
        super(const HouseholdState()) {
    on<LoadMembers>(_onLoadMembers);
    on<LoadArchivedMembers>(_onLoadArchivedMembers);
    on<CreateMember>(_onCreateMember);
    on<UpdateMember>(_onUpdateMember);
    on<ToggleMemberActive>(_onToggleMemberActive);
    on<ArchiveMember>(_onArchiveMember);
    on<RestoreMember>(_onRestoreMember);
    on<DeleteMemberPermanently>(_onDeleteMemberPermanently);
    on<CheckCanArchive>(_onCheckCanArchive);
  }

  final HouseholdMemberRepository _memberRepository;

  Future<void> _onLoadMembers(
    LoadMembers event,
    Emitter<HouseholdState> emit,
  ) async {
    emit(state.copyWith(status: HouseholdStatus.loading));

    try {
      final members = await _memberRepository.getMembers(
        activeOnly: event.activeOnly,
      );

      emit(
        state.copyWith(
          status: HouseholdStatus.success,
          members: members,
          showingArchived: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HouseholdStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadArchivedMembers(
    LoadArchivedMembers event,
    Emitter<HouseholdState> emit,
  ) async {
    emit(state.copyWith(status: HouseholdStatus.loading));

    try {
      final archivedMembers = await _memberRepository.getArchivedMembers();

      emit(
        state.copyWith(
          status: HouseholdStatus.success,
          archivedMembers: archivedMembers,
          showingArchived: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HouseholdStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateMember(
    CreateMember event,
    Emitter<HouseholdState> emit,
  ) async {
    try {
      final newMember = await _memberRepository.createMember(event.member);
      final updatedMembers = [...state.members, newMember];

      emit(state.copyWith(members: updatedMembers));
    } catch (e) {
      emit(
        state.copyWith(
          status: HouseholdStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateMember(
    UpdateMember event,
    Emitter<HouseholdState> emit,
  ) async {
    try {
      final updatedMember = await _memberRepository.updateMember(event.member);
      final updatedMembers = state.members.map((m) {
        return m.id == updatedMember.id ? updatedMember : m;
      }).toList();

      emit(state.copyWith(members: updatedMembers));
    } catch (e) {
      emit(
        state.copyWith(
          status: HouseholdStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onToggleMemberActive(
    ToggleMemberActive event,
    Emitter<HouseholdState> emit,
  ) async {
    try {
      final updatedMember = await _memberRepository.toggleActive(event.id);
      final updatedMembers = state.members.map((m) {
        return m.id == updatedMember.id ? updatedMember : m;
      }).toList();

      emit(state.copyWith(members: updatedMembers));
    } catch (e) {
      emit(
        state.copyWith(
          status: HouseholdStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onArchiveMember(
    ArchiveMember event,
    Emitter<HouseholdState> emit,
  ) async {
    try {
      await _memberRepository.archiveMember(event.id);
      final updatedMembers =
          state.members.where((m) => m.id != event.id).toList();

      emit(state.copyWith(members: updatedMembers));
    } catch (e) {
      emit(
        state.copyWith(
          status: HouseholdStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRestoreMember(
    RestoreMember event,
    Emitter<HouseholdState> emit,
  ) async {
    try {
      final restoredMember = await _memberRepository.restoreMember(event.id);
      final updatedArchivedMembers =
          state.archivedMembers.where((m) => m.id != event.id).toList();
      final updatedMembers = [...state.members, restoredMember];

      emit(
        state.copyWith(
          members: updatedMembers,
          archivedMembers: updatedArchivedMembers,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HouseholdStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteMemberPermanently(
    DeleteMemberPermanently event,
    Emitter<HouseholdState> emit,
  ) async {
    try {
      await _memberRepository.deleteMemberPermanently(event.id);
      final updatedArchivedMembers =
          state.archivedMembers.where((m) => m.id != event.id).toList();

      emit(state.copyWith(archivedMembers: updatedArchivedMembers));
    } catch (e) {
      emit(
        state.copyWith(
          status: HouseholdStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCheckCanArchive(
    CheckCanArchive event,
    Emitter<HouseholdState> emit,
  ) async {
    try {
      final canArchive = await _memberRepository.canArchiveMember(event.id);
      emit(state.copyWith(canArchiveMember: canArchive));
    } catch (e) {
      emit(state.copyWith(canArchiveMember: false));
    }
  }
}
