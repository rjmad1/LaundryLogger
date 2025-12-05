import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_logger/core/database/database_helper.dart';
import 'package:laundry_logger/features/household/data/repositories/household_member_repository_impl.dart';
import 'package:laundry_logger/features/household/domain/entities/household_member.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late HouseholdMemberRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.instance;
    await databaseHelper.resetDatabase();
    repository = HouseholdMemberRepositoryImpl(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  group('HouseholdMemberRepositoryImpl', () {
    group('getMembers', () {
      test('should return empty list initially', () async {
        final members = await repository.getMembers();
        expect(members, isEmpty);
      });

      test('should return all active members', () async {
        await repository.createMember(const HouseholdMember(name: 'Active 1'));
        await repository.createMember(const HouseholdMember(name: 'Active 2'));

        final members = await repository.getMembers();
        expect(members.length, equals(2));
        expect(members.every((m) => m.isActive && !m.isArchived), isTrue);
      });

      test('should filter by active status', () async {
        await repository.createMember(const HouseholdMember(
          name: 'Active',
        ),);
        final inactive = await repository.createMember(const HouseholdMember(
          name: 'Inactive',
        ),);
        await repository.toggleActive(inactive.id!);

        final activeOnly = await repository.getMembers();
        final all = await repository.getMembers(activeOnly: false);

        expect(activeOnly.length, equals(1));
        expect(all.length, equals(2));
      });

      test('should not return archived members', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'To Archive'),
        );
        await repository.archiveMember(member.id!);

        final members = await repository.getMembers();
        expect(members.any((m) => m.name == 'To Archive'), isFalse);
      });
    });

    group('getArchivedMembers', () {
      test('should return only archived members', () async {
        await repository.createMember(const HouseholdMember(name: 'Active'));
        final toArchive = await repository.createMember(
          const HouseholdMember(name: 'Archived'),
        );
        await repository.archiveMember(toArchive.id!);

        final archived = await repository.getArchivedMembers();
        expect(archived.length, equals(1));
        expect(archived.first.name, equals('Archived'));
        expect(archived.every((m) => m.isArchived), isTrue);
      });
    });

    group('getMemberById', () {
      test('should return member when exists', () async {
        final created = await repository.createMember(
          const HouseholdMember(name: 'Find Me'),
        );

        final found = await repository.getMemberById(created.id!);
        expect(found, isNotNull);
        expect(found!.name, equals('Find Me'));
      });

      test('should return null when not exists', () async {
        final found = await repository.getMemberById(99999);
        expect(found, isNull);
      });

      test('should return archived members too', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'Archived Find'),
        );
        await repository.archiveMember(member.id!);

        final found = await repository.getMemberById(member.id!);
        expect(found, isNotNull);
        expect(found!.isArchived, isTrue);
      });
    });

    group('createMember', () {
      test('should create member with generated id', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'New Member', color: '#FF0000'),
        );

        expect(member.id, isNotNull);
        expect(member.id, isPositive);
        expect(member.name, equals('New Member'));
        expect(member.color, equals('#FF0000'));
        expect(member.createdAt, isNotNull);
      });

      test('should default to active and not archived', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'Defaults'),
        );

        expect(member.isActive, isTrue);
        expect(member.isArchived, isFalse);
      });
    });

    group('updateMember', () {
      test('should update member fields', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'Original', color: '#000000'),
        );

        final updated = await repository.updateMember(
          member.copyWith(name: 'Updated', color: '#FFFFFF'),
        );

        expect(updated.name, equals('Updated'));
        expect(updated.color, equals('#FFFFFF'));

        final fetched = await repository.getMemberById(member.id!);
        expect(fetched!.name, equals('Updated'));
      });

      test('should throw for member without id', () async {
        expect(
          () => repository.updateMember(const HouseholdMember(name: 'No ID')),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toggleActive', () {
      test('should toggle active status', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'Toggle'),
        );

        final toggled = await repository.toggleActive(member.id!);
        expect(toggled.isActive, isFalse);

        final toggledAgain = await repository.toggleActive(member.id!);
        expect(toggledAgain.isActive, isTrue);
      });
    });

    group('archiveMember', () {
      test('should archive active member', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'To Archive'),
        );

        final result = await repository.archiveMember(member.id!);
        expect(result, isTrue);

        final fetched = await repository.getMemberById(member.id!);
        expect(fetched!.isArchived, isTrue);
      });
    });

    group('restoreMember', () {
      test('should restore archived member', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'To Restore'),
        );
        await repository.archiveMember(member.id!);

        final restored = await repository.restoreMember(member.id!);
        expect(restored.isArchived, isFalse);

        final members = await repository.getMembers();
        expect(members.any((m) => m.name == 'To Restore'), isTrue);
      });
    });

    group('deleteMemberPermanently', () {
      test('should delete archived member', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'To Delete'),
        );
        await repository.archiveMember(member.id!);

        final result = await repository.deleteMemberPermanently(member.id!);
        expect(result, isTrue);

        final fetched = await repository.getMemberById(member.id!);
        expect(fetched, isNull);
      });

      test('should throw for active member', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'Active'),
        );

        expect(
          () => repository.deleteMemberPermanently(member.id!),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('canArchiveMember', () {
      test('should return true for member without transactions', () async {
        final member = await repository.createMember(
          const HouseholdMember(name: 'No Txns'),
        );

        final canArchive = await repository.canArchiveMember(member.id!);
        expect(canArchive, isTrue);
      });
    });
  });
}
