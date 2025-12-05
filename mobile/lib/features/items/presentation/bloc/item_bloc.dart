import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/laundry_item.dart';
import '../../domain/repositories/item_repository.dart';

part 'item_event.dart';
part 'item_state.dart';

/// BLoC for managing laundry items.
class ItemBloc extends Bloc<ItemEvent, ItemState> {
  /// Creates a new ItemBloc.
  ItemBloc({required ItemRepository itemRepository})
      : _itemRepository = itemRepository,
        super(const ItemState()) {
    on<LoadItems>(_onLoadItems);
    on<LoadArchivedItems>(_onLoadArchivedItems);
    on<LoadFavoriteItems>(_onLoadFavoriteItems);
    on<SearchItems>(_onSearchItems);
    on<CreateItem>(_onCreateItem);
    on<UpdateItem>(_onUpdateItem);
    on<ArchiveItem>(_onArchiveItem);
    on<RestoreItem>(_onRestoreItem);
    on<DeleteItemPermanently>(_onDeleteItemPermanently);
    on<ToggleFavorite>(_onToggleFavorite);
    on<ReorderItems>(_onReorderItems);
    on<CheckCanArchive>(_onCheckCanArchive);
  }

  final ItemRepository _itemRepository;

  Future<void> _onLoadItems(LoadItems event, Emitter<ItemState> emit) async {
    emit(state.copyWith(status: ItemStatus.loading));

    try {
      final items = await _itemRepository.getItems(category: event.category);
      final categories = await _itemRepository.getCategories();

      emit(
        state.copyWith(
          status: ItemStatus.success,
          items: items,
          categories: categories,
          selectedCategory: event.category,
          showingArchived: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadArchivedItems(
    LoadArchivedItems event,
    Emitter<ItemState> emit,
  ) async {
    emit(state.copyWith(status: ItemStatus.loading));

    try {
      final archivedItems = await _itemRepository.getArchivedItems();

      emit(
        state.copyWith(
          status: ItemStatus.success,
          archivedItems: archivedItems,
          showingArchived: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadFavoriteItems(
    LoadFavoriteItems event,
    Emitter<ItemState> emit,
  ) async {
    emit(state.copyWith(status: ItemStatus.loading));

    try {
      final items = await _itemRepository.getFavoriteItems();

      emit(
        state.copyWith(
          status: ItemStatus.success,
          items: items,
          showingArchived: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSearchItems(
    SearchItems event,
    Emitter<ItemState> emit,
  ) async {
    emit(state.copyWith(status: ItemStatus.loading));

    try {
      final items = await _itemRepository.searchItems(event.query);

      emit(
        state.copyWith(
          status: ItemStatus.success,
          items: items,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateItem(CreateItem event, Emitter<ItemState> emit) async {
    try {
      final newItem = await _itemRepository.createItem(event.item);
      final updatedItems = [...state.items, newItem];
      final categories = await _itemRepository.getCategories();

      emit(
        state.copyWith(
          items: updatedItems,
          categories: categories,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateItem(UpdateItem event, Emitter<ItemState> emit) async {
    try {
      final updatedItem = await _itemRepository.updateItem(event.item);
      final updatedItems = state.items.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList();
      final categories = await _itemRepository.getCategories();

      emit(
        state.copyWith(
          items: updatedItems,
          categories: categories,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onArchiveItem(
    ArchiveItem event,
    Emitter<ItemState> emit,
  ) async {
    try {
      await _itemRepository.archiveItem(event.id);
      final updatedItems =
          state.items.where((item) => item.id != event.id).toList();
      final categories = await _itemRepository.getCategories();

      emit(
        state.copyWith(
          items: updatedItems,
          categories: categories,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRestoreItem(
    RestoreItem event,
    Emitter<ItemState> emit,
  ) async {
    try {
      final restoredItem = await _itemRepository.restoreItem(event.id);
      final updatedArchivedItems =
          state.archivedItems.where((item) => item.id != event.id).toList();
      final updatedItems = [...state.items, restoredItem];

      emit(
        state.copyWith(
          items: updatedItems,
          archivedItems: updatedArchivedItems,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteItemPermanently(
    DeleteItemPermanently event,
    Emitter<ItemState> emit,
  ) async {
    try {
      await _itemRepository.deleteItemPermanently(event.id);
      final updatedArchivedItems =
          state.archivedItems.where((item) => item.id != event.id).toList();

      emit(
        state.copyWith(
          archivedItems: updatedArchivedItems,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<ItemState> emit,
  ) async {
    try {
      final updatedItem = await _itemRepository.toggleFavorite(event.id);
      final updatedItems = state.items.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList();

      emit(state.copyWith(items: updatedItems));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onReorderItems(
    ReorderItems event,
    Emitter<ItemState> emit,
  ) async {
    try {
      await _itemRepository.reorderItems(event.itemIds);
      // Reload items to get updated order
      add(LoadItems(category: state.selectedCategory));
    } catch (e) {
      emit(
        state.copyWith(
          status: ItemStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCheckCanArchive(
    CheckCanArchive event,
    Emitter<ItemState> emit,
  ) async {
    try {
      final canArchive = await _itemRepository.canArchiveItem(event.id);
      emit(state.copyWith(canArchiveItem: canArchive));
    } catch (e) {
      emit(state.copyWith(canArchiveItem: false));
    }
  }
}
