import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/anonymous_guard.dart';
import 'package:chatbond/config/router/auth_guard.dart';
import 'package:chatbond/config/router/router.dart';
import 'package:chatbond/data/repositories/authentication_repository/authentication_repository.dart';
import 'package:chatbond/data/repositories/secure_storage_repo.dart';
import 'package:chatbond/data/repositories/user_repo/user_repo.dart';
import 'package:chatbond/presentation/authentication/bloc/authentication_bloc.dart';
import 'package:chatbond/presentation/login/login_page/login_bloc.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Used to select if we use the dark or light theme, start with system mode.
  ThemeMode themeMode = ThemeMode.system;
  // Opt in/out on Material 3
  bool useMaterial3 = false;

  @override
  Widget build(BuildContext context) {
    // Select the predefined FlexScheme color scheme to use. Modify the
    // used FlexScheme enum value below to try other pre-made color schemes.
    const usedScheme = FlexScheme.bahamaBlue;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthenticationRepository>(
          create: (context) => AuthenticationRepository(
            secureStorageRepo: getIt.get<SecureStorageRepo>(),
            apiClient: getIt.get<ApiClient>(),
          ),
        ),
        RepositoryProvider<UserRepo>(
          create: (context) => UserRepo(
            apiClient: getIt.get<ApiClient>(),
          ),
        ),
      ],
      child: BlocProvider<AuthenticationBloc>(
        create: (context) => AuthenticationBloc(
          authenticationRepository: context.read<AuthenticationRepository>(),
          userRepo: context.read<UserRepo>(),
        ),
        child: BlocProvider(
          create: (context) => LoginFormBloc(
            authenticationRepository: context.read<AuthenticationRepository>(),
            authenticationBloc: context.read<AuthenticationBloc>(),
          ),
          child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (context, state) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                builder: (context, child) => ResponsiveBreakpoints.builder(
                  child: child!,
                  breakpoints: [
                    const Breakpoint(start: 0, end: 600, name: MOBILE),
                    const Breakpoint(start: 601, end: 900, name: TABLET),
                    const Breakpoint(start: 901, end: 1920, name: DESKTOP),
                    const Breakpoint(
                      start: 1921,
                      end: double.infinity,
                      name: '4K',
                    ),
                  ],
                ),
                theme: FlexThemeData.light(
                  scheme: usedScheme,
                  // Use very subtly themed app bar elevation in light mode.
                  appBarElevation: 0.5,
                  // Opt in/out of using Material 3.
                  useMaterial3: useMaterial3,
                  // We use the nicer Material 3 Typography in both M2 and M3 mode.
                  typography:
                      Typography.material2021(platform: defaultTargetPlatform),
                ),
                darkTheme: FlexThemeData.dark(
                  scheme: usedScheme,
                  // Use a bit more themed elevated app bar in dark mode.
                  appBarElevation: 2,
                  // Opt in/out of using Material 3.
                  useMaterial3: useMaterial3,
                  // We use the nicer Material 3 Typography in both M2 and M3 mode.
                  typography:
                      Typography.material2021(platform: defaultTargetPlatform),
                ),
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                routerConfig: RootRouter(
                  AuthGuard(authBloc: context.read<AuthenticationBloc>()),
                  AnonymousGuard(authBloc: context.read<AuthenticationBloc>()),
                ).config(
                  navigatorObservers: () => [
                    AutoRouteObserver(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
