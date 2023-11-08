import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/repositories/authentication_repository/authentication_repository.dart';
import 'package:chatbond/presentation/authentication/bloc/authentication_bloc.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';
import 'package:loggy/loggy.dart';

class LoginFormBloc extends FormBloc<String, String> with BlocLogger {
  LoginFormBloc({
    required this.authenticationRepository,
    required this.authenticationBloc,
  }) {
    addFieldBlocs(
      fieldBlocs: [
        email,
        password,
      ],
    );
  }

  final AuthenticationRepository authenticationRepository;
  final AuthenticationBloc authenticationBloc;

  // ignore: inference_failure_on_instance_creation
  final email = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.email,
    ],
  );

  // ignore: inference_failure_on_instance_creation
  final password = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
    ],
  );

  @override
  Future<void> onSubmitting() async {
    try {
      await authenticationRepository.logIn(
        email: email.value,
        password: password.value,
      );
      authenticationBloc.add(Authenticated());

      // OneSignal.initialize(oneSignalKey);
      logInfo('Successfully logged in');

      emitSuccess();
      email.clear();
      password.clear();
    } catch (e) {
      logError('failed to log in with exception $e');
      emitFailure(
        failureResponse: LocaleKeys.authenticationFailed.tr().toCapitalized(),
      );
    }
  }
}
