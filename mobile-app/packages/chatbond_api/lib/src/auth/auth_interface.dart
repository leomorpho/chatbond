import 'package:chatbond_api/chatbond_api.dart';
import 'package:chatbond_api/src/auth/serializer/token_refresh.dart';

abstract class AuthInterface {
  Future<User> signup({
    required String email,
    required String password,
    required String name,
    required String? dateOfBirth,
  });
  Future<bool> login({required String email, required String password});
  Future<TokenRefresh> refreshToken({required String refreshToken});
  Future<bool> verifyToken({required String token});
  void logout();
  Future<bool> checkEmailAvailability(String email);
}
