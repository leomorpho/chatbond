import 'dart:async';

import 'package:chatbond/data/repositories/authentication_repository/authentication_repository.dart';

abstract class IAuthenticationRepository {
  Stream<AuthenticationStatus> get status;
  Future<bool> isAlreadyLoggedIn();
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String? dateOfBirth,
  });
  Future<void> logIn({required String email, required String password});
  Future<void> logOut();
  void triggerTokenExpired();
  void dispose();
  Future<bool> checkEmailAvailability(String email);
}
