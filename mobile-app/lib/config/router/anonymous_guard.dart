// mock auth state
import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/authentication_repository/authentication_repository.dart';
import 'package:chatbond/presentation/authentication/bloc/authentication_bloc.dart';
import 'package:loggy/loggy.dart';

class AnonymousGuard extends AutoRouteGuard {
  const AnonymousGuard({
    required AuthenticationBloc authBloc,
  }) : _authBloc = authBloc;
  final AuthenticationBloc _authBloc;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final status = _authBloc.state.status;
    logDebug('AnonymousGuard - status is $status.');
    if (status == AuthenticationStatus.authenticated) {
      await resolver.redirect(const HomeFeedRoute());
    } else {
      logDebug('AnonymousGuard - going to ${router.topRoute.name}');
      resolver.next();
    }
  }
}
