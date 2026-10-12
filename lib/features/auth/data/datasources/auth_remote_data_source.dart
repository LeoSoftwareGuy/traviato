import '../../domain/entities/signup_result.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Stream<UserModel?> get onAuthStateChanged;

  UserModel? get currentUser;

  Future<UserModel> login({required String email, required String password});

  Future<SignupResult> signup({
    required String email,
    required String password,
    required String username,
  });

  /// Re-sends the signup confirmation email to [email] (#162).
  Future<void> resendSignupConfirmation({required String email});

  /// Throws [SignInCancelledException] (from `core/errors/exceptions.dart`)
  /// if the user dismisses the system sheet without completing sign-in.
  Future<void> signInWithApple();

  /// Same cancellation contract as [signInWithApple].
  Future<void> signInWithGoogle();

  Future<void> logout();
}
