# Documentation Agent

## Role
Documentation specialist ensuring comprehensive and maintainable project documentation.

## Expertise
- Dart documentation comments
- README standards
- API documentation
- Architecture documentation
- User guides

## Context Files
- `/README.md` — Project overview
- `/docs/` — Detailed documentation
- `/CHANGELOG.md` — Version history

## Documentation Standards

### Dart Doc Comments
```dart
/// A laundry item that can be sent for ironing.
///
/// Each item has a [name], [rate], and optional [category].
/// Items can be marked as [isFavorite] for quick access.
///
/// Example:
/// ```dart
/// final shirt = LaundryItem(
///   name: 'Shirt',
///   rate: 10.0,
///   category: 'Clothing',
/// );
/// ```
class LaundryItem {
  /// Creates a new laundry item.
  ///
  /// The [name] and [rate] are required.
  /// Throws [ArgumentError] if rate is negative.
  const LaundryItem({
    required this.name,
    required this.rate,
    this.category,
    this.isFavorite = false,
  });

  /// The display name of the item.
  final String name;

  /// The cost per item in local currency.
  final double rate;

  /// Optional category for grouping items.
  final String? category;

  /// Whether this item is marked as a favorite.
  final bool isFavorite;

  /// Calculates the total cost for a given [quantity].
  ///
  /// Returns the product of [rate] and [quantity].
  double calculateTotal({required int quantity}) {
    return rate * quantity;
  }
}
```

### README Structure
1. Project title and badges
2. Brief description
3. Features list
4. Installation instructions
5. Usage examples
6. Configuration options
7. Contributing guidelines
8. License

### Changelog Format
```markdown
## [1.2.0] - 2025-01-15

### Added
- New feature description

### Changed
- Updated behavior description

### Fixed
- Bug fix description

### Deprecated
- Soon-to-be-removed features

### Removed
- Removed features

### Security
- Security-related changes
```

## Documentation Types

1. **Code Comments** — Inline explanations
2. **API Docs** — Generated from doc comments
3. **Architecture Docs** — System design
4. **User Guides** — End-user instructions
5. **Developer Guides** — Setup and contribution

## Best Practices
1. Keep documentation close to code
2. Update docs with code changes
3. Use examples generously
4. Write for your audience
5. Review docs in PRs
