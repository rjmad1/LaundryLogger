# Testing Strategy

## Overview

Laundry Logger follows a comprehensive testing strategy to ensure reliability and maintainability.

## Testing Pyramid

```
        ╱╲
       ╱  ╲
      ╱ E2E╲           Few, critical user journeys
     ╱──────╲
    ╱        ╲
   ╱Integration╲       Widget + BLoC integration
  ╱────────────╲
 ╱              ╲
╱  Unit Tests    ╲     Many, fast, isolated tests
╱────────────────╲
```

## Test Categories

### 1. Unit Tests

**Location:** `mobile/test/unit/`

**Coverage:**
- Domain entities and value objects
- Use cases and business logic
- Repository implementations
- BLoC/Cubit state transitions
- Utility functions

**Example:**
```dart
group('LaundryItem', () {
  test('should calculate total cost correctly', () {
    final item = LaundryItem(
      name: 'Shirt',
      quantity: 5,
      rate: 10.0,
    );
    expect(item.totalCost, equals(50.0));
  });
});
```

### 2. Widget Tests

**Location:** `mobile/test/widget/`

**Coverage:**
- Individual widget rendering
- Widget interactions
- Form validation
- UI state changes

**Example:**
```dart
testWidgets('ItemCard displays item details', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ItemCard(item: testItem),
    ),
  );
  
  expect(find.text('Shirt'), findsOneWidget);
  expect(find.text('₹50.00'), findsOneWidget);
});
```

### 3. Integration Tests

**Location:** `mobile/test/integration/`

**Coverage:**
- BLoC + Repository integration
- Database operations
- Multi-screen workflows
- State persistence

### 4. E2E Tests

**Location:** `mobile/integration_test/`

**Coverage:**
- Complete user journeys
- Critical paths (add item, send, receive)
- Export functionality
- Backup/restore flow

## Running Tests

```bash
# Run all unit and widget tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test

# Run specific test file
flutter test test/unit/item_test.dart
```

## Code Coverage

**Target:** 80% minimum coverage

```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Mocking Strategy

Using `mocktail` for creating mocks:

```dart
class MockItemRepository extends Mock implements ItemRepository {}

void main() {
  late MockItemRepository mockRepository;
  
  setUp(() {
    mockRepository = MockItemRepository();
  });
  
  test('should fetch items', () async {
    when(() => mockRepository.getAll())
        .thenAnswer((_) async => [testItem]);
    
    final items = await mockRepository.getAll();
    expect(items, hasLength(1));
  });
}
```

## CI Integration

Tests run automatically on:
- Pull request creation
- Push to main branch
- Scheduled nightly builds

## Best Practices

1. **Test naming:** Use descriptive names (`should_return_empty_list_when_no_items`)
2. **Arrange-Act-Assert:** Follow AAA pattern
3. **Single responsibility:** One assertion per test when possible
4. **Mock external dependencies:** Isolate units under test
5. **Test edge cases:** Empty lists, null values, error states
