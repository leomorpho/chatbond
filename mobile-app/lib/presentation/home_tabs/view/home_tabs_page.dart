import 'package:auto_route/auto_route.dart';
import 'package:chatbond/bootstrap.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/constants.dart';
import 'package:chatbond/data/repositories/authentication_repository/authentication_repository.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/data/repositories/invitation_repo/invitations_repo.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/data/repositories/realtime_repo/realtime_repo.dart';
import 'package:chatbond/data/repositories/user_repo/user_repo.dart';
import 'package:chatbond/presentation/authentication/bloc/authentication_bloc.dart';
import 'package:chatbond/presentation/chats/chats/chat_threads_page/chat_threads_bloc/chat_threads_bloc.dart';
import 'package:chatbond/presentation/chats/chats/chat_threads_page/invitations_cubit.dart';
import 'package:chatbond/presentation/home_tabs/view/notifs_cubit.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond/utils.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

@RoutePage()
class HomeTabsRouterPage extends StatefulWidget {
  const HomeTabsRouterPage({super.key});

  @override
  State<HomeTabsRouterPage> createState() => _HomeTabsRouterPageState();
}

class _HomeTabsRouterPageState extends State<HomeTabsRouterPage> {
  late VisibilityChangeNotifier _visibilityChangeNotifier;

  @override
  void initState() {
    super.initState();

    _visibilityChangeNotifier = VisibilityChangeNotifier(
      thresholdInSeconds: visibilityChangeNotifierTimespan,
      onThresholdExceeded: () async {
        // Replace this line with the code you want to execute when threshold is exceeded
        logDebug('access token invalid, attempting to log in automatically...');
        await context
            .read<AuthenticationRepository>()
            .validateTokenAndLogoutIfInvalid();
      },
    );
  }

  @override
  void dispose() {
    _visibilityChangeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state.status == AuthenticationStatus.unauthenticated) {
          // Redirect to HomePage when user is unauthenticated, the authGuard
          // will catch the login and then redirect to HomeFeed. It's a
          // little convoluted, but meshes fine with the auto_route guard.
          logDebug(
            'Attempted to access protected routes while unauthenticated, redirecting...',
          );
          AutoRouter.of(context).replaceAll(
            [
              const HomeTabsRouterRoute(),
              const HomeFeedRouter(),
            ],
          );
        }
      },
      child: FutureBuilder(
        future: context.read<UserRepo>().getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Builder(
              builder: (context) {
                return ChangeNotifierProvider(
                  create: (context) => ChatProvider(),
                  child: Builder(
                    builder: (context) {
                      final chatProvider = context.read<ChatProvider>();

                      return MultiRepositoryProvider(
                        providers: [
                          RepositoryProvider<ChatThreadsRepo>(
                            create: (context) => ChatThreadsRepo(
                              apiClient: getIt.get<ApiClient>(),
                              chatThreadsSink:
                                  chatProvider.chatThreadsController.sink,
                              questionThreadsSink:
                                  chatProvider.questionThreadsController.sink,
                              questionChatsSink:
                                  chatProvider.questionChatsController.sink,
                              interlocutorSink:
                                  chatProvider.interlocutorsController.sink,
                              chatThreadRequestsStream: chatProvider
                                  .chatThreadRequestsController.stream,
                              questionThreadRequestsStream: chatProvider
                                  .questionThreadRequestsController.stream,
                              interlocutorRequestsStream: chatProvider
                                  .interlocutorRequestsController.stream,
                            ),
                          ),
                          RepositoryProvider<InvitationsRepo>(
                            create: (context) => InvitationsRepo(
                              apiClient: getIt.get<ApiClient>(),
                            ),
                          ),
                          RepositoryProvider<QuestionsRepo>(
                            create: (context) => QuestionsRepo(
                              apiClient: getIt.get<ApiClient>(),
                            ),
                          ),
                        ],
                        child: Builder(
                          builder: (context) {
                            return MultiRepositoryProvider(
                              providers: [
                                RepositoryProvider<RealtimeRepo>(
                                  lazy: false,
                                  create: (context) => RealtimeRepo(
                                    apiClient: getIt.get<ApiClient>(),
                                    userId:
                                        getIt.get<GlobalState>().currUser!.id,
                                    chatsRepo: context.read<ChatThreadsRepo>(),
                                  ),
                                ),
                              ],
                              child: MultiBlocProvider(
                                providers: [
                                  BlocProvider<ChatThreadsBloc>(
                                    create: (BuildContext context) =>
                                        ChatThreadsBloc(
                                      invitationsRepo:
                                          context.read<InvitationsRepo>(),
                                      chatThreadsRepo:
                                          context.read<ChatThreadsRepo>(),
                                      numTotalNotificationsController:
                                          chatProvider
                                              .numTotalNotificationsController,
                                    ),
                                  ),
                                  BlocProvider<InvitationsCubit>(
                                    create: (BuildContext context) =>
                                        InvitationsCubit(
                                      invitationRepo:
                                          context.read<InvitationsRepo>(),
                                      realtimeRepo:
                                          context.read<RealtimeRepo>(),
                                    )..fetchInvitations(),
                                  ),
                                  BlocProvider<NotificationCubit>(
                                    create: (BuildContext context) =>
                                        NotificationCubit(
                                      context
                                          .read<ChatProvider>()
                                          .numTotalNotificationsController
                                          .stream,
                                    ),
                                  ),
                                ],
                                child: createAutoTabsMenu(context),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
          return const LoadingDialog(); // Or a loading screen
        },
      ),
    );
  }

  AutoTabsRouter createAutoTabsMenu(BuildContext context) {
    return AutoTabsRouter(
      lazyLoad: false, // Gets all data for all tabs at once
      routes: const [
        HomeFeedRoute(),
        PeopleListRoute(),
        ProfileRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = context.tabsRouter;
        return Scaffold(
          bottomNavigationBar: AnimatedBuilder(
            animation: tabsRouter,
            builder: (_, __) => _buildBottomBar(context, tabsRouter),
          ),
          body: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
              ? Row(
                  children: [
                    _buildNavRail(
                      context,
                      tabsRouter,
                    ), // This is your NavigationRail
                    Expanded(child: child), // This would be your main content
                  ],
                )
              : child,
        );
      },
    );
  }

  void onTabChanged(int index) {
    logInfo('Tab changed to: $index');
  }
}

Widget _buildNavRail(BuildContext context, TabsRouter tabsRouter) {
  return SafeArea(
    child: NavigationRail(
      selectedIndex: tabsRouter.activeIndex,
      onDestinationSelected: (int index) {
        tabsRouter.setActiveIndex(index);
      },
      extended: ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/chatbond/apple-icon-72x72.png',
          height: 36,
          width: 36,
        ),
      ),
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: FriendsIconWithNotifications(),
          label: Text('Friends'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('You'),
        ),
      ],
    ),
  );
}

Widget _buildBottomBar(BuildContext context, TabsRouter tabsRouter) {
  final hideBottomNav = context.topRouteMatch.meta['hideBottomNav'] == true;
  if (hideBottomNav || ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
    return const SizedBox.shrink();
  }
  if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
    return const SizedBox.shrink();
  } else {
    return SalomonBottomBar(
      margin: const EdgeInsets.fromLTRB(60, 5, 60, 5),
      currentIndex: tabsRouter.activeIndex,
      onTap: (index) {
        tabsRouter.setActiveIndex(index);
      },
      items: [
        /// Home
        SalomonBottomBarItem(
          icon: const Icon(Icons.home),
          title: const Text('Home'),
          selectedColor: Colors.purple,
        ),

        /// Friends
        SalomonBottomBarItem(
          icon: const FriendsIconWithNotifications(),
          title: const Text('Friends'),
          selectedColor: Colors.pink,
        ),

        /// Profile
        SalomonBottomBarItem(
          icon: const Icon(Icons.settings),
          title: const Text('You'),
          selectedColor: Colors.teal,
        ),
      ],
    );
  }
}

class FriendsIconWithNotifications extends StatelessWidget {
  const FriendsIconWithNotifications({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, int>(
      builder: (context, notificationCount) {
        return Stack(
          children: <Widget>[
            const Icon(Icons.people),
            if (notificationCount > 0)
              Positioned(
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
