import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';

class PasswordResetConfirmFormBloc extends FormBloc<String, String>
    with BlocLogger {
  PasswordResetConfirmFormBloc({
    required this.userRepo,
    required this.uid,
    required this.token,
  }) {
    addFieldBlocs(
      fieldBlocs: [
        password,
      ],
    );
    password.addValidators([_passwordLengthValidator(minPasswordLength)]);
  }

  final UserRepo userRepo;
  final String uid;
  final String token;

  final TextFieldBloc<String> password = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
    ],
  );

  Validator<String> _passwordLengthValidator(int minLength) {
    return (String? password) {
      return passwordLengthValidator(password, minLength);
    };
  }

  @override
  Future<void> onSubmitting() async {
    try {
      await userRepo.resetPasswordConfirm(
        uid: uid,
        token: token,
        newPassword: password.value,
      );
      emitSuccess();
    } catch (e) {
      debugPrint('failed to reset new password with exception: $e');
      emitFailure(
        failureResponse:
            'Failed to set new password, was that reset link already used?',
      );
    }
  }
}
