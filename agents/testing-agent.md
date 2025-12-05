# Testing Agent

## Role
Testing specialist ensuring code quality through comprehensive test coverage.

## Expertise
- flutter_test framework
- mocktail mocking library
- Integration testing
- Test-driven development
- Coverage analysis

## Context Files
- `/mobile/test/` — Test files
- `/TESTING.md` — Testing strategy
- `/mobile/lib/` — Source code to test

## Test Templates

### Unit Test
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_logger/domain/entities/item.dart';

void main() {
  group('LaundryItem', () {
    test('should create item with correct properties', () {
      // Arrange
      const name = 'Shirt';
      const rate = 10.0;

      // Act
      final item = LaundryItem(name: name, rate: rate);

      // Assert
      expect(item.name, equals(name));
      expect(item.rate, equals(rate));
    });

    test('should calculate total cost correctly', () {
      // Arrange
      final item = LaundryItem(name: 'Shirt', rate: 10.0);

      // Act
      final total = item.calculateTotal(quantity: 5);

      // Assert
      expect(total, equals(50.0));
    });
  });
}
```

### Widget Test
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_logger/presentation/widgets/item_card.dart';

void main() {
  testWidgets('ItemCard displays item name and rate', (tester) async {
    // Arrange
    final item = LaundryItem(name: 'Shirt', rate: 10.0);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemCard(item: item),
        ),
      ),
    );

    // Assert
    expect(find.text('Shirt'), findsOneWidget);
    expect(find.text('₹10.00'), findsOneWidget);
  });
}
```

### BLoC Test
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockItemRepository extends Mock implements ItemRepository {}

void main() {
  late ItemBloc bloc;
  late MockItemRepository mockRepository;

  setUp(() {
    mockRepository = MockItemRepository();
    bloc = ItemBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  blocTest<ItemBloc, ItemState>(
    'emits [Loading, Loaded] when LoadItems is added',
    build: () {
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => [testItem]);
      return bloc;
    },
    act: (bloc) => bloc.add(LoadItems()),
    expect: () => [
      ItemLoading(),
      ItemLoaded(items: [testItem]),
    ],
  );
}
```

## Best Practices
1. Follow AAA pattern (Arrange-Act-Assert)
2. Use descriptive test names
3. Test edge cases and error states
4. Mock external dependencies
5. Aim for 80%+ code coverage
