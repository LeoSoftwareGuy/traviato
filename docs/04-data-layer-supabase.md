# 04 — Data Layer (Supabase)

The data layer is the *only* place `supabase_flutter` is imported. It has three parts per
feature: **data sources** (raw Supabase calls → throw exceptions), **models** (`fromJson`),
and **repository implementations** (catch exceptions → return `Either<Failure, T>`).

## Data source: interface + Supabase implementation

Define an abstract interface, then a Supabase implementation. The interface returns **models**
(the repository maps them to entities — which is free because models *are* entities).

```dart
// datasources/auth_remote_data_source.dart
abstract interface class AuthRemoteDataSource {
  Stream<UserModel?> get onAuthStateChanged;
  Future<UserModel> login({required String email, required String password});
  Future<void> logout();
}

// datasources/supabase_auth_remote_data_source.dart
class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  SupabaseAuthRemoteDataSource({required SupabaseClient client}) : _client = client;
  final SupabaseClient _client;

  @override
  Future<UserModel> login({required String email, required String password}) async {
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) {
        throw const AuthenticationException(message: 'Login succeeded but no user returned.');
      }
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (e) {
      throw AuthenticationException(message: e.message);
    } on AuthenticationException {
      rethrow;                          // our own throw above — don't double-wrap
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }
}
```

### The canonical Supabase `catch` ladder

Every data-source method uses the same ordered `on` clauses. Order matters (specific first):

```dart
try {
  // ... supabase call ...
} on AuthenticationException {          // rethrow our own guard exceptions
  rethrow;
} on PostgrestException catch (e) {     // database / RPC / RLS errors
  if (e.code == PostgresErrors.insufficientPrivilege) {          // '42501'
    throw PermissionException(message: e.message);
  }
  if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {   // 'PGRST116'
    throw NotFoundException(message: e.message);
  }
  throw DatabaseException(message: e.message);
} on StorageException catch (e) {       // only for storage calls
  throw StorageServerException(message: e.message);
} on SocketException {                  // offline
  throw const NetworkException();
} catch (e) {                           // anything else
  throw UnknownException(message: e.toString());
}
```

### Auth guard

Every authenticated call checks the session first and throws early:

```dart
if (_client.auth.currentUser == null) {
  throw const AuthenticationException(message: 'User is not authenticated');
}
```

## Models: `Model extends Entity` + JSON

Models live in the data layer, extend the domain entity, and add JSON. Use
`@JsonSerializable(createToJson: false)` (we only read from Supabase in most cases). Map
snake_case columns with `@JsonKey(name: ...)` on overridden getters.

```dart
@JsonSerializable(createToJson: false)
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    super.avatarUrl,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  // domain metadata → typed model (e.g. from Supabase auth user)
  factory UserModel.fromSupabaseUser(User user) {
    final meta = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      username: meta['username'] as String? ?? '',
      avatarUrl: meta['avatar_url'] as String?,
      role: meta['role'] as String? ?? Roles.user,
    );
  }

  @JsonKey(name: 'avatar_url')
  @override
  String? get avatarUrl;                // override getter just to attach @JsonKey
}
```

Because `UserModel` **is** a `UserEntity`, the repository can return it directly where an
entity is expected — no manual `toEntity()` mapping needed.

### `@JsonKey` placement: field vs getter override

When the model is a **standalone class** (does not extend an entity), put `@JsonKey` directly
on the field:

```dart
// standalone model — @JsonKey on the field declaration
class UserModel {
  @JsonKey(name: 'first_name') final String firstName;
  @JsonKey(name: 'last_name')  final String lastName;
}
```

When the model **extends an entity** (the field is already declared in the superclass), you
cannot annotate the field again — instead override the getter and annotate the override:

```dart
// model extending entity — @JsonKey on the overridden getter
class PostDisplayModel extends PostDisplay {
  @JsonKey(name: 'post_id')
  @override
  String get postId;

  @JsonKey(name: 'author_avatar_url')
  @override
  String? get authorAvatarUrl;
}
```

The generator reads whichever annotation it finds. Field annotation works on fresh models;
getter override is required when the field's origin is the entity superclass.

## Repository implementation

Implements the domain interface, catches exceptions, returns `Either`. See
[03](03-error-handling.md) for the full mapping. Repositories may also adapt streams (e.g.
wrap a data-source stream in a `StreamController`, add `onError` handling that emits a safe
fallback and logs).

## Supabase access patterns

| Operation | Use | Example |
|-----------|-----|---------|
| Read a list | `.from(view).select().order(...).range(offset, offset+limit-1)` | pagination |
| Read one | `.from(view).select().eq('id', id).single()` | detail page |
| Complex write returning a row | **RPC** `.rpc(fn, params: {...}).single()` | create/update that must return the joined display row |
| Simple delete | `.from(table).delete().match({'id': id})` | |
| Toggle / server logic | **RPC** | like toggle, counters |
| File upload | `.storage.from(bucket).upload(path, file)` then `.getPublicUrl(path)` | |
| List / delete files | `.storage.from(bucket).list(path:)` / `.remove([...])` | delete a post's image folder |
| Realtime | channel / stream subscription (see doc 08) | live new-post feed |

### Prefer views & RPC for read/complex writes

When a screen needs joined/aggregated data (author name, like count, `current_user_liked`),
read from a **Postgres view** (e.g. `post_display_view`) rather than joining client-side.
For a create/update that must return that same shaped row atomically, call an **RPC** that
inserts and returns the view row. This keeps the client dumb and the shape consistent.

### Pagination math

`range` is inclusive on both ends. For an `offset`/`limit` window:

```dart
final to = offset + limit - 1;
final rows = await _client.from(view).select().order(...).range(offset, to);
```

### Storage paths

Namespace uploads by user and entity so RLS and cleanup are simple:

```dart
final path = 'public/$userId/$postId/${const Uuid().v4()}.$ext';
```

Generate the entity id client-side with `uuid` when you need the storage path *before* the
DB insert, then pass the same id into the insert RPC.

## Constants — never hard-code Supabase identifiers

Centralize every table/view/bucket/RPC name and known error code in
`core/constants/supabase_constants.dart`:

```dart
abstract class Tables    { static const posts = 'posts'; static const comments = 'comments'; }
abstract class Views     { static const postDisplayView = 'post_display_view'; }
abstract class Storage   { static const postImages = 'post-images'; static const avatars = 'avatars'; }
abstract class DBFunctions { static const handleLike = 'handle_like'; /* ... */ }
abstract class PostgresErrors {
  static const insufficientPrivilege = '42501';
  static const moreThanOneOrNoItemsReturned = 'PGRST116';
}
abstract class Roles { static const admin = 'admin'; static const user = 'user'; }
```

## Rules

- Data source methods return **models**, take primitive/`File` params, and never see `Failure`.
- Never build a `Failure` in the data layer; never build an `Exception` in the repository.
- One `try` per public method with the canonical ladder — don't sprinkle nested try/catch.
- `@JsonSerializable(createToJson: false)` unless you actually serialize *to* Supabase.
- No hard-coded strings for tables/columns/buckets/RPCs — use the constants classes.
