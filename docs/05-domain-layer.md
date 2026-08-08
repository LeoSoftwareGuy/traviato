# 05 — Domain Layer

The domain layer is pure Dart: **entities**, **repository interfaces**, and (only when
warranted) **use cases**. No Flutter, no Supabase, no JSON. It depends only on `equatable`,
`fpdart`, and `core/errors`.

## Entities

Immutable value objects extending `Equatable`. `final` fields, `const` constructor, `props`
lists every field, plus a `copyWith`.

```dart
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.role,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final String role;

  @override
  List<Object?> get props => [id, username, avatarUrl, role];
}
```

Rules:
- Every entity extends `Equatable` and lists **all** fields in `props` (use `Object?` when any
  field is nullable).
- No JSON, no `fromJson` in entities — that belongs to the model subclass in the data layer.
- Keep entities behavior-light: they hold data and maybe trivial derived getters, not I/O.

### `copyWith` and the nullable-field trap

A plain `copyWith(String? avatarUrl)` can't tell "leave unchanged" from "set to null". When a
field is nullable and you need to *clear* it, wrap that parameter in a `Function()`:

```dart
PostDisplay copyWith({
  String? title,                          // non-nullable: normal pattern
  String? Function()? imageUrl,           // nullable & clearable: function wrapper
}) {
  return PostDisplay(
    title: title ?? this.title,
    imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
  );
}
```

Call sites:
- keep current: `post.copyWith(title: 'x')`
- set to null: `post.copyWith(imageUrl: () => null)`
- set a value: `post.copyWith(imageUrl: () => url)`

Apply the same wrapper trick to nullable fields on **state** classes.

## Repository interfaces

Abstract interface declaring what the feature can do, in domain terms, returning `Either`.

```dart
abstract interface class AuthRepository {
  Stream<UserEntity?> get onAuthStateChanged;
  Future<Either<Failure, void>> login({required String email, required String password});
  Future<Either<Failure, void>> signup({
    required String email, required String password, required String username,
  });
  Future<Either<Failure, void>> logout();
}
```

Rules:
- Use `abstract interface class` (Dart 3 pure interface).
- Methods return `Future<Either<Failure, T>>` (or `Stream<...>`). Never expose exceptions.
- Named parameters for anything with 2+ args or where call-site clarity matters.
- The implementation lives in the **data** layer (`AuthRepositoryImpl`).

## Use cases — optional, not default

The reference project wraps every repository call in a use-case class + a `Params` object +
a Riverpod provider. For a typical app that is **too much boilerplate**. Guidance:

### Default: skip use cases

Let controllers and mutations depend on the **repository** directly:

```dart
@riverpod
class MyProfileController extends _$MyProfileController {
  @override
  Future<UserEntity> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    return (await repo.getProfile(userId)).fold(
      (f) => throw PresentationFailureException(f),
      (profile) => profile,
    );
  }
}
```

### Add a use case only when there's real logic

Introduce a use case when a single operation:
- orchestrates **multiple** repositories or calls (e.g. "update post" = upload new image →
  delete old image → update row), **or**
- performs non-trivial transformation/validation/business rules, **or**
- must be reused identically from several controllers/mutations.

When you do, use this shape:

```dart
abstract interface class UseCase<Return, Params> {
  Future<Either<Failure, Return>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}

class UpdatePostUseCase implements UseCase<PostDisplay, UpdatePostParams> {
  UpdatePostUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  @override
  Future<Either<Failure, PostDisplay>> call(UpdatePostParams p) async {
    // real orchestration: upload image, remove old folder, then update row
    // ...
  }
}
```

`Params` classes are `Equatable`. Use `NoParams` for zero-argument use cases so the
`call(params)` signature stays uniform.

> Do **not** create a use case that is a one-line pass-through to the repository. That's the
> anti-pattern we're dropping from the reference project.

## DTOs

Small non-entity data holders that cross the domain boundary (inputs/outputs that aren't
persisted entities) live in `domain/.../dto/` — e.g. `ImageUploadResult { postId, imageUrl }`.
Keep them `Equatable` too.
