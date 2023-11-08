import 'package:chatbond_api/src/users/serializer/user.dart';

abstract class UserInterface {
  Future<User> getUserDetails();
  Future<User> updateUser({required User updatedUser});
  Future<User> patchUser({required Map<String, dynamic> updatedFields});
  Future<void> deleteUser();

  Future<bool> activateUser({required String uid, required String token});
  Future<bool> resendActivationEmail({required String email});
  Future<bool> sendResetEmail({required String email});
  Future<bool> confirmResetEmail({required String newEmail});

  Future<void> resetPassword({required String email});
  Future<bool> resetPasswordConfirm({
    required String uid,
    required String token,
    required String newPassword,
  });

  Future<bool> setEmail({
    required String currentPassword,
    required String newEmail,
  });
  Future<bool> setPassword({
    required String currentPassword,
    required String newPassword,
  });
}
