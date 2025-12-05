import '../../../../core/database/database_helper.dart';
import '../../domain/entities/household_member.dart';
import '../../domain/repositories/household_member_repository.dart';
import '../models/household_member_model.dart';

/// SQLite implementation of [HouseholdMemberRepository].
///
/// Uses soft-delete pattern via is_archived column.
class HouseholdMemberRepositoryImpl implements HouseholdMemberRepository {
  /// Creates a new HouseholdMemberRepositoryImpl.
  HouseholdMemberRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<HouseholdMember>> getMembers({bool activeOnly = true}) async {
    var where = 'is_archived = 0';
    if (activeOnly) {
      where += ' AND is_active = 1';
    }

    final maps = await _databaseHelper.query(
      DatabaseHelper.tableMembers,
      where: where,
      orderBy: 'name ASC',
    );

    return maps
        .map((map) => HouseholdMemberModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<List<HouseholdMember>> getArchivedMembers() async {
    final maps = await _databaseHelper.query(
      DatabaseHelper.tableMembers,
      where: 'is_archived = 1',
      orderBy: 'name ASC',
    );

    return maps
        .map((map) => HouseholdMemberModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<HouseholdMember?> getMemberById(int id) async {
    final maps = await _databaseHelper.query(
      DatabaseHelper.tableMembers,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return HouseholdMemberModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<HouseholdMember> createMember(HouseholdMember member) async {
    final model = HouseholdMemberModel.fromEntity(member);
    final id = await _databaseHelper.insert(
      DatabaseHelper.tableMembers,
      model.toInsertMap(),
    );

    return member.copyWith(id: id, createdAt: DateTime.now());
  }

  @override
  Future<HouseholdMember> updateMember(HouseholdMember member) async {
    if (member.id == null) {
      throw ArgumentError('Member must have an id to update');
    }

    final model = HouseholdMemberModel.fromEntity(member);
    await _databaseHelper.update(
      DatabaseHelper.tableMembers,
      model.toUpdateMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );

    return member;
  }

  @override
  Future<HouseholdMember> toggleActive(int id) async {
    final member = await getMemberById(id);
    if (member == null) {
      throw ArgumentError('Member not found: $id');
    }

    final updated = member.copyWith(isActive: !member.isActive);
    return updateMember(updated);
  }

  @override
  Future<bool> archiveMember(int id) async {
    // Check for pending transactions first
    final canArchive = await canArchiveMember(id);
    if (!canArchive) {
      throw StateError(
        'Cannot archive member with pending transactions. '
        'Mark all transactions as returned first.',
      );
    }

    final count = await _databaseHelper.update(
      DatabaseHelper.tableMembers,
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<HouseholdMember> restoreMember(int id) async {
    await _databaseHelper.update(
      DatabaseHelper.tableMembers,
      {'is_archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    final member = await getMemberById(id);
    if (member == null) {
      throw ArgumentError('Member not found: $id');
    }
    return member;
  }

  @override
  Future<bool> deleteMemberPermanently(int id) async {
    // Only allow permanent deletion of archived members
    final member = await getMemberById(id);
    if (member == null) return false;

    if (!member.isArchived) {
      throw StateError(
        'Cannot permanently delete active members. Archive first.',
      );
    }

    final count = await _databaseHelper.delete(
      DatabaseHelper.tableMembers,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<bool> canArchiveMember(int id) async {
    // Check for pending transactions (status != 'returned')
    final pendingTransactions = await _databaseHelper.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTransactions}
      WHERE member_id = ? AND status != 'returned'
    ''', [id],);

    final count = pendingTransactions.first['count'] as int? ?? 0;
    return count == 0;
  }
}
