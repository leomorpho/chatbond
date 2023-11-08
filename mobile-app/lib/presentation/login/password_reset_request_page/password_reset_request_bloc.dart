import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';

class PasswordResetRequestFormBloc extends FormBloc<String, String>
    with BlocLogger {
  PasswordResetRequestFormBloc({
    required this.userRepo,
  }) {
    addFieldBlocs(
      fieldBlocs: [
        email,
      ],
    );
  }

  final UserRepo userRepo;

  final email = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.email,
    ],
  );

  @override
  Future<void> onSubmitting() async {
    debugPrint(email.value);

    try {
      await userRepo.resetPassword(email: email.value);
      emitSuccess();
    } catch (e) {
      debugPrint('failed to send password reset email with exception: $e');
      emitFailure(
        failureResponse:
            LocaleKeys.failedSendingPasswordResetEmail.tr().toCapitalized(),
      );
    }
  }
}
