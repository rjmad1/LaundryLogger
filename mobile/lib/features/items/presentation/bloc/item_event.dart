part of 'item_bloc.dart';

/// Base class for item events.
sealed class ItemEvent extends Equatable {
  const ItemEvent();

  @override
  List<Object?> get props => [];
}

/// Load all items.
final class LoadItems extends ItemEvent {
  const LoadItems({this.category});

  final String? category;

  @override
  List<Object?> get props => [category];
}

/// Load archived items.
final class LoadArchivedItems extends ItemEvent {
  const LoadArchivedItems();
}

/// Load favorite items.
final class LoadFavoriteItems extends ItemEvent {
  const LoadFavoriteItems();
}

/// Search items.
final class SearchItems extends ItemEvent {
  const SearchItems(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Create a new item.
final class CreateItem extends ItemEvent {
  const CreateItem(this.item);

  final LaundryItem item;

  @override
  List<Object?> get props => [item];
}

/// Update an existing item.
final class UpdateItem extends ItemEvent {
  const UpdateItem(this.item);

  final LaundryItem item;

  @override
  List<Object?> get props => [item];
}

/// Archive an item (soft-delete).
final class ArchiveItem extends ItemEvent {
  const ArchiveItem(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Restore an archived item.
final class RestoreItem extends ItemEvent {
  const RestoreItem(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Permanently delete an archived item.
final class DeleteItemPermanently extends ItemEvent {
  const DeleteItemPermanently(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Toggle favorite status of an item.
final class ToggleFavorite extends ItemEvent {
  const ToggleFavorite(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Reorder items.
final class ReorderItems extends ItemEvent {
  const ReorderItems(this.itemIds);

  final List<int> itemIds;

  @override
  List<Object?> get props => [itemIds];
}

/// Check if an item can be archived.
final class CheckCanArchive extends ItemEvent {
  const CheckCanArchive(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
