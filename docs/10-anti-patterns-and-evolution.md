# 10 — Anti-patterns & How the Codebase Evolved

These patterns appear across the other projects in the knowledge base. They represent
**earlier or simpler approaches** — useful to understand, but not what we use in production
code with Riverpod + Supabase.

---

## ❌ Legacy Riverpod: `StateNotifier` / `StateNotifierProvider`

Seen in: `meals/filters_provider.dart`, `favorite_places/user_places.dart`

```dart
// ❌ OLD — do not use
import 'package:flutter_riverpod/legacy.dart';           // red flag import

class FiltersNotifier extends StateNotifier<Map<Filter, bool>> { ... }

final filtersProvider =
    StateNotifierProvider<FiltersNotifier, Map<Filter, bool>>((ref) {
      return FiltersNotifier();
    });
```

**Why it's obsolete:** `StateNotifier` is the Riverpod 1.x API. It has no code-gen, no
auto-dispose by default, and requires manual generics everywhere. The new equivalent is a
code-gen `@riverpod class` notifier.

```dart
// ✅ NEW — use this
@riverpod
class FiltersNotifier extends _$FiltersNotifier {
  @override
  Map<Filter, bool> build() => {
    Filter.glutenFree: false,
    Filter.lactoseFree: false,
    Filter.vegan: false,
    Filter.vegetarian: false,
  };

  void setFilter(Filter filter, bool isActive) {
    state = {...state, filter: isActive};
  }
}
```

**Red flags to grep for:**
- `import 'package:flutter_riverpod/legacy.dart'`
- `extends StateNotifier<`
- `StateNotifierProvider<`
- `ChangeNotifierProvider(`  (the even older pattern)

---

## ❌ Network calls inside `StatefulWidget.initState` + `setState`

Seen in: `shopping_list/grocery_list.dart`

```dart
// ❌ ANTI-PATTERN — mixing concerns, not reactive, not testable
class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();        // async call directly from widget lifecycle
  }

  void _loadItems() async {
    try {
      final response = await http.get(url);
      setState(() { _groceryItems = ...; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Failed...'; });
    }
  }
}
```

Also seen: an `_isSending` boolean flag in `StatefulWidget` to manage form submission state.

**Why it's wrong:** Business logic and state live in the widget. Can't be tested without
rendering. No type-safe error, no retry, no caching, no reactivity.

```dart
// ✅ Correct: async state in an AsyncNotifier
@riverpod
class GroceryListController extends _$GroceryListController {
  @override
  Future<List<GroceryItem>> build() async {
    final repo = ref.watch(groceryRepositoryProvider);
    return (await repo.getItems()).fold(
      (f) => throw PresentationFailureException(f),
      (items) => items,
    );
  }
}

// form submission -> Mutation (not _isSending setState)
final addItemMutation = Mutation<GroceryItem>();
```

---

## ❌ `Either<String, T>` — untyped error Left

Seen in: `either_type/product_repository.dart`

```dart
// ❌ Anti-pattern: raw String as error type
Future<Either<String, Product>> fetchEitherProduct(int id) async { ... }
```

Using `String` as the Left type is the first step past raw exceptions, but it loses the
semantic category of the error. You can't distinguish "not found" from "network offline"
from "permission denied" without string parsing.

```dart
// ✅ Typed Failure subclasses: pattern-matchable, carry intent
Future<Either<Failure, Product>> fetchProduct(int id) async {
  // repository converts exceptions to Failure subtypes
  // callers can switch on (f) { NotFoundFailure() => ..., NetworkFailure() => ..., }
}
```

The key insight from `either_type`: the direction is right (return instead of throw), the
Left type is wrong. Always use a typed `Failure` hierarchy, not raw `String` or `Object`.

---

## ❌ `get_it` / `injectable` as the DI container

Seen in: `injectable_primer/`

```dart
// ❌ Not our stack — separate DI container, annotation-driven
final getIt = GetIt.instance;

@LazySingleton(as: RandomAdviceRepository)
class RandomAdviceRepositoryImpl implements RandomAdviceRepository { ... }

// usage: getIt<RandomAdviceRepository>()
```

**Why we don't use it:** Requires a separate `get_it` singleton and annotation scanning.
Changes to the dependency graph require regenerating `di.config.dart`. Testing requires
overriding the `getIt` container.

Riverpod providers *are* the DI container — no separate package, no global singleton,
overrides are built-in (`ProviderScope(overrides: [...])`), and it's reactive.

```dart
// ✅ Riverpod as DI — reactive, testable, no extra singleton
@riverpod
RandomAdviceRepository randomAdviceRepository(Ref ref) =>
    RandomAdviceRepositoryImpl(api: ref.watch(apiServiceProvider));
```

---

## ⚠️ `context.mounted` — the widget equivalent of `ref.mounted`

Seen in: `shopping_list/new_item.dart`

```dart
// ✅ This IS correct — needed in StatefulWidget async methods
final response = await http.post(url, ...);
if (!context.mounted) return;       // guard before using context after await
Navigator.of(context).pop(newItem);
```

This is the widget-level equivalent of `if (!ref.mounted) return;` in Riverpod notifiers.
Any time you `await` in a widget method and then use `context` (navigate, show snackbar, call
`setState`), guard with `if (!context.mounted) return;` first.

| Location | Guard |
|----------|-------|
| `StatefulWidget` async method | `if (!context.mounted) return;` |
| Riverpod `AsyncNotifier` / `Notifier` method | `if (!ref.mounted) return;` |

With Mutations, the framework handles the mounted check for you internally — another reason
to prefer Mutations over hand-rolled async in widgets.

---

## ✅ Named constructors as model factories

Seen in: `expense_tracker/expense.dart`

```dart
class ExpenseBucket {
  const ExpenseBucket({required this.category, required this.expenses});

  // Named constructor: build from a filter over another list
  ExpenseBucket.forCategory(List<Expense> allExpenses, this.category)
    : expenses = allExpenses.where((e) => e.category == category).toList();
}
```

Named constructors are a clean Dart way to offer alternative construction paths without
factory methods. In the data layer you already use this pattern (`UserModel.fromSupabaseUser`).
Use named constructors in models when:
- The object can be built from multiple source formats (Supabase user, JSON, local cache).
- The alternative constructor has meaningfully different logic from `fromJson`.

---

## ✅ Enum + const map for icon/label lookups

Seen in: `expense_tracker/expense.dart`

```dart
enum Category { food, travel, leisure, work }

const categoryIcons = {
  Category.food: Icons.restaurant,
  Category.travel: Icons.flight_takeoff,
};
```

The `enum` + associated `const Map` pattern pairs well with `switch`/pattern matching:

```dart
final icon = categoryIcons[category] ?? Icons.help_outline;

// Or exhaustive switch (compiler-checked):
final label = switch (category) {
  Category.food    => 'Food',
  Category.travel  => 'Travel',
  Category.leisure => 'Leisure',
  Category.work    => 'Work',
};
```

Prefer exhaustive `switch` over the `Map` lookup when you need the compiler to flag missing
cases after adding a new enum value.

---

## ✅ Dart callable classes — the `call()` operator

Seen in: `callable_classes/callable_classes.dart`

```dart
class CallableClass {
  void call(String name) { print('Hello $name'); }
}
final c = CallableClass();
c('World');      // same as c.call('World')
```

And the nullable version:
```dart
String Function(int)? mayBeFun = ...;
print(mayBeFun?.call(1));    // safe call on nullable function
```

**Why this matters for our architecture:**

1. **Use cases are callable.** `UseCase` declares `call(params)`. You can invoke a use case
   as `useCase(params)` (just like a function), which is why this signature is conventional:
   ```dart
   class LoginUseCase implements UseCase<void, LoginParams> {
     Future<Either<Failure, void>> call(LoginParams params) => ...;
   }
   // usage: await useCase(params)  <-- calls .call() implicitly
   ```

2. **`copyWith`'s nullable `Function()?` wrapper.** The `String? Function()? imageUrl`
   parameter pattern leverages the same concept — a nullable callable. Calling `imageUrl()`
   invokes the wrapped getter:
   ```dart
   // Distinguishes "set to null" from "leave unchanged":
   post.copyWith(imageUrl: () => null);   // imageUrl?.call() -> null  -> clears field
   post.copyWith(imageUrl: () => url);    // imageUrl?.call() -> url   -> sets field
   post.copyWith();                        // imageUrl is null, field unchanged
   ```

Understanding `call()` makes both of these patterns feel natural rather than magic.
