import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/repositories/authentication_repository/authentication_repository.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';
import 'package:chatbond/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:loggy/loggy.dart';

class SignUpFormBloc extends FormBloc<String, String> with BlocLogger {
  SignUpFormBloc({
    required AuthenticationRepository authenticationRepository,
    bool askForAge = false,
  })  : _authenticationRepository = authenticationRepository,
        _askForAge = askForAge {
    addFieldBlocs(
      fieldBlocs: [
        email,
        username,
        // birthdate,
        password,
      ],
    );
    password.addValidators([_passwordLengthValidator(minPasswordLength)]);
    // birthdate.addValidators([_isOldEnough()]);
  }

  final AuthenticationRepository _authenticationRepository;
  final bool _askForAge;

  final email = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.email,
    ],
    asyncValidatorDebounceTime: const Duration(milliseconds: 1000),
  );

  final username = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
    ],
  );

  final birthdate = InputFieldBloc<DateTime?, dynamic>(
    initialValue: null,
    validators: [
      FieldBlocValidators.required, // Add a validator for >13y old
    ],
  );

  final password = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
    ],
  );

  Validator<String> _passwordLengthValidator(int minLength) {
    return (String? password) {
      return passwordLengthValidator(password, minLength);
    };
  }

  Validator<DateTime?> _isOldEnough() {
    return (DateTime? birthdate) {
      if (birthdate != null) {
        final notOldEnough = birthdate.isAfter(
          DateTime.now().subtract(const Duration(days: 365 * minAge)),
        );
        if (notOldEnough) {
          return 'You must be at least $minAge years old.';
        }
      }
      return null;
    };
  }

  @override
  Future<void> onSubmitting() async {
    if (_askForAge &&
        (birthdate.value == null ||
            birthdate.value!.isAfter(
              DateTime.now().subtract(const Duration(days: 365 * 13)),
            ))) {
      emitFailure(
        failureResponse:
            "You must be over 13 years old to use this app", // TODO: never shown even if needed
      );
    }
    try {
      String? formattedDate;
      if (_askForAge) {
        final date = birthdate.value!;
        formattedDate =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }
      logDebug('registering...');
      await _authenticationRepository.register(
        email: email.value,
        password: password.value,
        dateOfBirth: _askForAge ? formattedDate : null,
        name: username.value,
      );
      logDebug('Now registered!');
      emitSuccess();
    } catch (e) {
      logError('failed to sign up with exception $e');
      emitFailure(
        failureResponse: LocaleKeys.signupFailed.tr().toCapitalized(),
      );
    }
  }
}
