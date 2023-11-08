import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/anonymous_guard.dart';
import 'package:chatbond/config/router/auth_guard.dart';
import 'package:chatbond/config/router/router.gr.dart';

@AutoRouterConfig(
  replaceInRouteName: 'Page,Route',
  // deferredLoading: true, // Fuck, now I get errors when I turn this on....it used to work...
)
class RootRouter extends $RootRouter {
  RootRouter(this.authGuard, this.anonymousGuard);
  @override
  RouteType get defaultRouteType => const RouteType.material();

  AuthGuard authGuard;
  AnonymousGuard anonymousGuard;

  final answerQuestionRoute = AutoRoute(
    path: 'questionDraft',
    page: AnswerQuestionRoute.page,
    meta: const {'hideBottomNav': true},
  );

  @override
  late final List<AutoRoute> routes = [
    AutoRoute(
      path: '/auth',
      guards: [authGuard], // AuthGuard applied here
      page: HomeTabsRouterRoute.page,
      children: [
        AutoRoute(
          path: 'profile',
          page: ProfileRouter.page,
          children: [
            AutoRoute(
              path: '',
              page: ProfileRoute.page,
            ),
            AutoRoute(
              page: ProfileEditRoute.page,
              path: 'editProfile',
              meta: const {'hideBottomNav': true},
            ),
            AutoRoute(
              path: 'questions',
              page: MultipurposeQuestionsRoute.page,
              meta: const {'hideBottomNav': true},
            ),
            AutoRoute(
              path: 'questionThreads',
              page: MultipurposeQuestionThreadsRoute.page,
              meta: const {'hideBottomNav': true},
            ),
            AutoRoute(
              path: 'questionThread/:questionThreadId',
              page: QuestionChatsRoute.page,
              meta: const {'hideBottomNav': true},
            ),
            answerQuestionRoute
          ],
        ),
        AutoRoute(
          page: HomeFeedRouter.page,
          path: 'home',
          children: [
            AutoRoute(
              page: HomeFeedRoute.page,
              path: '',
            ),
            AutoRoute(
              page: AnswerQuestionRoute.page,
              path: 'questionDraft',
              meta: const {'hideBottomNav': true},
            )
          ],
        ),
        AutoRoute(
          page: EmptyRouterRoute.page,
          path: 'people',
          children: [
            AutoRoute(
              path: '',
              page: PeopleListRoute.page,
            ),
            AutoRoute(
              path: 'createInvitation',
              page: CreateInvitationRoute.page,
              meta: const {'hideBottomNav': true},
            ),
            AutoRoute(
              path: 'manuallyAcceptInvitation',
              page: ManuallyAcceptInvitationRoute.page,
              meta: const {'hideBottomNav': true},
            ),
            AutoRoute(
              path: 'invite/:token',
              page: AcceptInvitationRoute.page,
              meta: const {'hideBottomNav': true},
            ),
            AutoRoute(
              path: ':chatThread',
              page: QuestionThreadsRoute.page,
            ),
            AutoRoute(
              path: ':chatThread/:questionThread/chats',
              page: QuestionChatsRoute.page,
              meta: const {'hideBottomNav': true},
            ),
            answerQuestionRoute,
            AutoRoute(
              path: ':chatThread/pending',
              page: MultipurposeQuestionThreadsRoute.page,
              meta: const {'hideBottomNav': true},
            ),
            AutoRoute(
              path: ':chatThread/questions',
              page: MultipurposeQuestionsRoute.page,
              meta: const {'hideBottomNav': true},
            ),
          ],
        ),
      ],
    ),
    AutoRoute(
      path: '/',
      page: AnonymousRouterRoute.page,
      guards: [anonymousGuard],
      children: [
        CustomRoute(
          path: 'home',
          page: LandingRoute.page,
          initial: true,
          transitionsBuilder: TransitionsBuilders.fadeIn,
        ),
        CustomRoute(
          path: 'login',
          page: LoginRoute.page,
          transitionsBuilder: TransitionsBuilders.fadeIn,
        ),
        AutoRoute(
          path: 'signup',
          page: SignUpRoute.page,
        ),
        AutoRoute(
          path: 'terms',
          page: UserTermsRoute.page,
        ),
        AutoRoute(
          path: 'password-reset-request',
          page: PasswordResetRoute.page,
        ),
        AutoRoute(
          path: 'password-reset/:uid/:token',
          page: PasswordResetConfirmRoute.page,
        ),
        AutoRoute(
          path: 'activate/:uid/:token',
          page: AccountActivationRoute.page,
        ),
      ],
    ),
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}
