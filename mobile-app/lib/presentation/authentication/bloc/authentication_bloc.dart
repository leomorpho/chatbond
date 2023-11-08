import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:loggy/loggy.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required AuthenticationRepository authenticationRepository,
    required UserRepo userRepo,
  })  : _authenticationRepository = authenticationRepository,
        _userRepo = userRepo,
        super(const AuthenticationState.unknown()) {
    // TODO: I wonder if we should not also look in secure storage if we're already logged in. If yes, emit appropriate state.

    _authenticationStatusSubscription = _authenticationRepository.status.listen(
      (status) {
        logInfo(
          'AuthenticationBloc received new status from AuthenticationRepository: $status',
        );
        add(_AuthenticationStatusChanged(status));
      },
      onError: (err) {
        logError('Received error: $err');
      },
    );
    on<_AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
    on<AuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);
    // The below is a hack because due to the async nature of the AuthBloc
    // and the LoginBloc linking, I was facing race conditions. To review one day.
    on<Authenticated>(_performLoginActions);
  }

  final AuthenticationRepository _authenticationRepository;
  final UserRepo _userRepo;
  late StreamSubscription<AuthenticationStatus>
      _authenticationStatusSubscription;

  Future<void> _onAuthenticationStatusChanged(
    _AuthenticationStatusChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    switch (event.status) {
      case AuthenticationStatus.unauthenticated:
        logDebug('AuthenticationBloc: user unauthenticated');
        return emit(const AuthenticationState.unauthenticated());
      case AuthenticationStatus.authenticated:
        logDebug('AuthenticationBloc: user authenticated');
        await _userRepo.getCurrentUser();
        emit(
          const AuthenticationState.authenticated(),
        );
        return;
      case AuthenticationStatus.unknown:
        logDebug('AuthenticationBloc: unknown status');
        return emit(const AuthenticationState.unknown());
    }
  }

  Future<void> _performLoginActions(
    Authenticated event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _userRepo.getCurrentUser();
    emit(
      const AuthenticationState.authenticated(),
    );
  }

  void _onAuthenticationLogoutRequested(
    AuthenticationLogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) {
    logDebug('AuthenticationBloc - logging out...');
    _authenticationRepository.logOut();
    logDebug('AuthenticationBloc - logged out.');
  }

  @override
  Future<void> close() {
    logDebug('AuthenticationBloc - Closing...');
    _authenticationStatusSubscription.cancel();
    logDebug('AuthenticationBloc - Closed.');

    return super.close();
  }
}
