import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_logger/features/items/domain/entities/laundry_item.dart';
import 'package:laundry_logger/features/items/domain/repositories/item_repository.dart';
import 'package:laundry_logger/features/items/presentation/bloc/item_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockItemRepository extends Mock implements ItemRepository {}

void main() {
  late ItemRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const LaundryItem(name: 'Fallback', defaultRate: 0));
  });

  setUp(() {
    mockRepository = MockItemRepository();
  });

  group('ItemBloc', () {
    final testItems = [
      const LaundryItem(id: 1, name: 'Shirt', defaultRate: 25),
      const LaundryItem(id: 2, name: 'Pants', defaultRate: 30),
    ];

    group('LoadItems', () {
      blocTest<ItemBloc, ItemState>(
        'emits [loading, success] when LoadItems succeeds',
        build: () {
          when(() => mockRepository.getItems(category: any(named: 'category')))
              .thenAnswer((_) async => testItems);
          when(() => mockRepository.getCategories())
              .thenAnswer((_) async => ['Clothing']);
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const LoadItems()),
        expect: () => [
          const ItemState(status: ItemStatus.loading),
          ItemState(
            status: ItemStatus.success,
            items: testItems,
            categories: const ['Clothing'],
          ),
        ],
      );

      blocTest<ItemBloc, ItemState>(
        'emits [loading, failure] when LoadItems fails',
        build: () {
          when(() => mockRepository.getItems(category: any(named: 'category')))
              .thenThrow(Exception('Failed'));
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const LoadItems()),
        expect: () => [
          const ItemState(status: ItemStatus.loading),
          isA<ItemState>()
              .having((s) => s.status, 'status', ItemStatus.failure)
              .having((s) => s.error, 'error', isNotNull),
        ],
      );

      blocTest<ItemBloc, ItemState>(
        'loads items filtered by category',
        build: () {
          when(() => mockRepository.getItems(category: 'Clothing'))
              .thenAnswer((_) async => [testItems.first]);
          when(() => mockRepository.getCategories())
              .thenAnswer((_) async => ['Clothing']);
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const LoadItems(category: 'Clothing')),
        verify: (_) {
          verify(() => mockRepository.getItems(category: 'Clothing')).called(1);
        },
      );
    });

    group('LoadArchivedItems', () {
      final archivedItems = [
        const LaundryItem(id: 3, name: 'Old', defaultRate: 10, isArchived: true),
      ];

      blocTest<ItemBloc, ItemState>(
        'emits [loading, success] with archived items',
        build: () {
          when(() => mockRepository.getArchivedItems())
              .thenAnswer((_) async => archivedItems);
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const LoadArchivedItems()),
        expect: () => [
          const ItemState(status: ItemStatus.loading),
          ItemState(
            status: ItemStatus.success,
            archivedItems: archivedItems,
            showingArchived: true,
          ),
        ],
      );
    });

    group('CreateItem', () {
      blocTest<ItemBloc, ItemState>(
        'adds new item to state',
        build: () {
          when(() => mockRepository.createItem(any()))
              .thenAnswer((_) async => testItems.first);
          when(() => mockRepository.getCategories())
              .thenAnswer((_) async => ['Clothing']);
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(CreateItem(testItems.first)),
        expect: () => [
          ItemState(items: [testItems.first], categories: const ['Clothing']),
        ],
      );
    });

    group('ArchiveItem', () {
      blocTest<ItemBloc, ItemState>(
        'removes item from active list',
        seed: () => ItemState(status: ItemStatus.success, items: testItems),
        build: () {
          when(() => mockRepository.archiveItem(1))
              .thenAnswer((_) async => true);
          when(() => mockRepository.getCategories())
              .thenAnswer((_) async => ['Clothing']);
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const ArchiveItem(1)),
        expect: () => [
          ItemState(
            status: ItemStatus.success,
            items: [testItems[1]],
            categories: const ['Clothing'],
          ),
        ],
      );

      blocTest<ItemBloc, ItemState>(
        'emits failure when archive fails',
        seed: () => ItemState(status: ItemStatus.success, items: testItems),
        build: () {
          when(() => mockRepository.archiveItem(1))
              .thenThrow(StateError('Has pending transactions'));
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const ArchiveItem(1)),
        expect: () => [
          isA<ItemState>()
              .having((s) => s.status, 'status', ItemStatus.failure),
        ],
      );
    });

    group('RestoreItem', () {
      const archivedItem = LaundryItem(
        id: 3,
        name: 'Archived',
        defaultRate: 10,
        isArchived: true,
      );
      final restoredItem = archivedItem.copyWith(isArchived: false);

      blocTest<ItemBloc, ItemState>(
        'moves item from archived to active',
        seed: () => const ItemState(
          status: ItemStatus.success,
          archivedItems: [archivedItem],
        ),
        build: () {
          when(() => mockRepository.restoreItem(3))
              .thenAnswer((_) async => restoredItem);
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const RestoreItem(3)),
        expect: () => [
          ItemState(
            status: ItemStatus.success,
            items: [restoredItem],
          ),
        ],
      );
    });

    group('ToggleFavorite', () {
      blocTest<ItemBloc, ItemState>(
        'toggles favorite status',
        seed: () => ItemState(status: ItemStatus.success, items: testItems),
        build: () {
          when(() => mockRepository.toggleFavorite(1))
              .thenAnswer((_) async => testItems.first.copyWith(isFavorite: true));
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const ToggleFavorite(1)),
        expect: () => [
          isA<ItemState>().having(
            (s) => s.items.firstWhere((i) => i.id == 1).isFavorite,
            'isFavorite',
            true,
          ),
        ],
      );
    });

    group('SearchItems', () {
      blocTest<ItemBloc, ItemState>(
        'searches and returns matching items',
        build: () {
          when(() => mockRepository.searchItems('Shirt'))
              .thenAnswer((_) async => [testItems.first]);
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const SearchItems('Shirt')),
        expect: () => [
          const ItemState(status: ItemStatus.loading),
          ItemState(
            status: ItemStatus.success,
            items: [testItems.first],
            searchQuery: 'Shirt',
          ),
        ],
      );
    });

    group('CheckCanArchive', () {
      blocTest<ItemBloc, ItemState>(
        'updates canArchiveItem state',
        build: () {
          when(() => mockRepository.canArchiveItem(1))
              .thenAnswer((_) async => true);
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const CheckCanArchive(1)),
        expect: () => [
          const ItemState(),
        ],
      );

      blocTest<ItemBloc, ItemState>(
        'sets canArchiveItem to false on error',
        build: () {
          when(() => mockRepository.canArchiveItem(1))
              .thenThrow(Exception('Error'));
          return ItemBloc(itemRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const CheckCanArchive(1)),
        expect: () => [
          const ItemState(canArchiveItem: false),
        ],
      );
    });
  });
}
