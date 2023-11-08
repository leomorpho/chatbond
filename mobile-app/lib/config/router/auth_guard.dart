import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/authentication_repository/authentication_repository.dart';
import 'package:chatbond/presentation/authentication/bloc/authentication_bloc.dart';
import 'package:loggy/loggy.dart';

class AuthGuard extends AutoRouteGuard {
  const AuthGuard({
    required AuthenticationBloc authBloc,
  }) : _authBloc = authBloc;
  final AuthenticationBloc _authBloc;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final status = _authBloc.state.status;
    logDebug('AuthGuard - status is $status.');
    if (status == AuthenticationStatus.authenticated) {
      resolver.next();
    } else {
      logDebug('AuthGuard - nope, not authenticated.');
      await resolver.redirect(
        LoginRoute(
          onLoginSuccessCallback: () async {
            logDebug(
              'AuthGuard - Redirecting <3 ------------------------------',
            );
            resolver.next();
          },
        ),
      );
    }
  }
}
