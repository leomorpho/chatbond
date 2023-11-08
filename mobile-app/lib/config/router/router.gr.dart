// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i31;
import 'package:chatbond/presentation/chats/chats/answer_question/answer_question_page.dart'
    as _i4;
import 'package:chatbond/presentation/chats/chats/chat_threads_page/chats_threads_page.dart'
    as _i19;
import 'package:chatbond/presentation/chats/chats/question_chats_page/question_chats_page.dart'
    as _i24;
import 'package:chatbond/presentation/chats/chats/question_threads_page/main/question_threads_page.dart'
    as _i25;
import 'package:chatbond/presentation/chats/chats/question_threads_page/multipurpose_question_threads_page/multipurpose_question_threads_page.dart'
    as _i15;
import 'package:chatbond/presentation/chats/chats/question_threads_page/multipurpose_questions_page/multipurpose_questions_page.dart'
    as _i16;
import 'package:chatbond/presentation/chats/chats/question_threads_page/question_threads_router_page.dart'
    as _i26;
import 'package:chatbond/presentation/chats/chats_router_page.dart' as _i20;
import 'package:chatbond/presentation/chats/invitations/accept_invitation/accept_invitation_page.dart'
    as _i1;
import 'package:chatbond/presentation/chats/invitations/accept_invitation_manually/accept_invitation_manual_page.dart'
    as _i14;
import 'package:chatbond/presentation/chats/invitations/create_invitation/create_invitation_page.dart'
    as _i6;
import 'package:chatbond/presentation/empty_router_page.dart' as _i7;
import 'package:chatbond/presentation/friends/friends_router_page.dart' as _i8;
import 'package:chatbond/presentation/home_feed/home_feed_page.dart' as _i9;
import 'package:chatbond/presentation/home_feed/home_feed_router_page.dart'
    as _i10;
import 'package:chatbond/presentation/home_tabs/view/home_tabs_page.dart'
    as _i11;
import 'package:chatbond/presentation/landing/landing_page.dart' as _i12;
import 'package:chatbond/presentation/login/account_activation/account_activation_page.dart'
    as _i2;
import 'package:chatbond/presentation/login/anonymous_router_page.dart' as _i3;
import 'package:chatbond/presentation/login/auth_router_page.dart' as _i5;
import 'package:chatbond/presentation/login/login_page/login_page.dart' as _i13;
import 'package:chatbond/presentation/login/password_reset_confirm_page/password_reset_confirm_page.dart'
    as _i17;
import 'package:chatbond/presentation/login/password_reset_request_page/password_reset_request_page.dart'
    as _i18;
import 'package:chatbond/presentation/login/signup_page/signup_page.dart'
    as _i28;
import 'package:chatbond/presentation/login/user_terms_page.dart' as _i30;
import 'package:chatbond/presentation/profile/view/profile_edit_page/profile_edit_page.dart'
    as _i21;
import 'package:chatbond/presentation/profile/view/profile_page/profile_page.dart'
    as _i22;
import 'package:chatbond/presentation/profile/view/profile_router_page.dart'
    as _i23;
import 'package:chatbond/presentation/questions/questions_page.dart' as _i27;
import 'package:chatbond/presentation/splash/view/splash_page.dart' as _i29;
import 'package:chatbond_api/chatbond_api.dart' as _i33;
import 'package:flutter/material.dart' as _i32;

abstract class $RootRouter extends _i31.RootStackRouter {
  $RootRouter({super.navigatorKey});

  @override
  final Map<String, _i31.PageFactory> pagesMap = {
    AcceptInvitationRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<AcceptInvitationRouteArgs>(
          orElse: () =>
              AcceptInvitationRouteArgs(token: pathParams.getString('token')));
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.AcceptInvitationRoute(
          key: args.key,
          token: args.token,
        ),
      );
    },
    AccountActivationRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<AccountActivationRouteArgs>(
          orElse: () => AccountActivationRouteArgs(
                uid: pathParams.getString('uid'),
                token: pathParams.getString('token'),
              ));
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.AccountActivationPage(
          key: args.key,
          uid: args.uid,
          token: args.token,
        ),
      );
    },
    AnonymousRouterRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.AnonymousRouterPage(),
      );
    },
    AnswerQuestionRoute.name: (routeData) {
      final args = routeData.argsAs<AnswerQuestionRouteArgs>();
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i4.AnswerQuestionPage(
          key: args.key,
          question: args.question,
          allConnectedInterlocutors: args.allConnectedInterlocutors,
        ),
      );
    },
    AuthRouter.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i5.AuthRouter(),
      );
    },
    CreateInvitationRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i6.CreateInvitationPage(),
      );
    },
    EmptyRouterRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i7.EmptyRouterPage(),
      );
    },
    FriendsRouterRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.FriendsRouterPage(),
      );
    },
    HomeFeedRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i9.HomeFeedPage(),
      );
    },
    HomeFeedRouter.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i10.HomeFeedRouter(),
      );
    },
    HomeTabsRouterRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i11.HomeTabsRouterPage(),
      );
    },
    LandingRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i12.LandingPage(),
      );
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i13.LoginPage(
          key: args.key,
          onLoginSuccessCallback: args.onLoginSuccessCallback,
        ),
      );
    },
    ManuallyAcceptInvitationRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i14.ManuallyAcceptInvitationRoute(),
      );
    },
    MultipurposeQuestionThreadsRoute.name: (routeData) {
      final args = routeData.argsAs<MultipurposeQuestionThreadsRouteArgs>();
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i15.MultipurposeQuestionThreadsPage(
          key: args.key,
          chatThreadId: args.chatThreadId,
          questionThreadsPageType: args.questionThreadsPageType,
          currentInterlocutor: args.currentInterlocutor,
          allInterlocutors: args.allInterlocutors,
        ),
      );
    },
    MultipurposeQuestionsRoute.name: (routeData) {
      final args = routeData.argsAs<MultipurposeQuestionsRouteArgs>();
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i16.MultipurposeQuestionsPage(
          key: args.key,
          chatThreadId: args.chatThreadId,
          questionsPageType: args.questionsPageType,
          currentInterlocutor: args.currentInterlocutor,
          otherInterlocutors: args.otherInterlocutors,
        ),
      );
    },
    PasswordResetConfirmRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<PasswordResetConfirmRouteArgs>(
          orElse: () => PasswordResetConfirmRouteArgs(
                uid: pathParams.getString('uid'),
                token: pathParams.getString('token'),
              ));
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i17.PasswordResetConfirmPage(
          key: args.key,
          uid: args.uid,
          token: args.token,
        ),
      );
    },
    PasswordResetRoute.name: (routeData) {
      final args = routeData.argsAs<PasswordResetRouteArgs>(
          orElse: () => const PasswordResetRouteArgs());
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i18.PasswordResetPage(
          key: args.key,
          cameFromLogin: args.cameFromLogin,
        ),
      );
    },
    PeopleListRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i19.PeopleListPage(),
      );
    },
    PeopleRouter.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i20.PeopleRouter(),
      );
    },
    ProfileEditRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i21.ProfileEditPage(),
      );
    },
    ProfileRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i22.ProfilePage(),
      );
    },
    ProfileRouter.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i23.ProfileRouter(),
      );
    },
    QuestionChatsRoute.name: (routeData) {
      final args = routeData.argsAs<QuestionChatsRouteArgs>();
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i24.QuestionChatsPage(
          key: args.key,
          chatThreadId: args.chatThreadId,
          questionThreadId: args.questionThreadId,
          question: args.question,
          interlocutors: args.interlocutors,
          onSetToSeenSucceeded: args.onSetToSeenSucceeded,
        ),
      );
    },
    QuestionThreadsRoute.name: (routeData) {
      final args = routeData.argsAs<QuestionThreadsRouteArgs>();
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i25.QuestionThreadsPage(
          key: args.key,
          chatThreadId: args.chatThreadId,
          currentInterlocutor: args.currentInterlocutor,
          otherInterlocutors: args.otherInterlocutors,
        ),
      );
    },
    QuestionThreadsRouter.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<QuestionThreadsRouterArgs>(
          orElse: () => QuestionThreadsRouterArgs(
              questionThreadId: pathParams.getString('questionThread')));
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i26.QuestionThreadsRouter(
          key: args.key,
          questionThreadId: args.questionThreadId,
        ),
      );
    },
    QuestionsRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i27.QuestionsPage(),
      );
    },
    SignUpRoute.name: (routeData) {
      final args = routeData.argsAs<SignUpRouteArgs>(
          orElse: () => const SignUpRouteArgs());
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i28.SignUpPage(
          key: args.key,
          cameFromLogin: args.cameFromLogin,
        ),
      );
    },
    SplashRoute.name: (routeData) {
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i29.SplashPage(),
      );
    },
    UserTermsRoute.name: (routeData) {
      final args = routeData.argsAs<UserTermsRouteArgs>(
          orElse: () => const UserTermsRouteArgs());
      return _i31.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i30.UserTermsPage(
          key: args.key,
          cameFromSignup: args.cameFromSignup,
        ),
      );
    },
  };
}

/// generated route for
/// [_i1.AcceptInvitationRoute]
class AcceptInvitationRoute
    extends _i31.PageRouteInfo<AcceptInvitationRouteArgs> {
  AcceptInvitationRoute({
    _i32.Key? key,
    required String token,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          AcceptInvitationRoute.name,
          args: AcceptInvitationRouteArgs(
            key: key,
            token: token,
          ),
          rawPathParams: {'token': token},
          initialChildren: children,
        );

  static const String name = 'AcceptInvitationRoute';

  static const _i31.PageInfo<AcceptInvitationRouteArgs> page =
      _i31.PageInfo<AcceptInvitationRouteArgs>(name);
}

class AcceptInvitationRouteArgs {
  const AcceptInvitationRouteArgs({
    this.key,
    required this.token,
  });

  final _i32.Key? key;

  final String token;

  @override
  String toString() {
    return 'AcceptInvitationRouteArgs{key: $key, token: $token}';
  }
}

/// generated route for
/// [_i2.AccountActivationPage]
class AccountActivationRoute
    extends _i31.PageRouteInfo<AccountActivationRouteArgs> {
  AccountActivationRoute({
    _i32.Key? key,
    required String uid,
    required String token,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          AccountActivationRoute.name,
          args: AccountActivationRouteArgs(
            key: key,
            uid: uid,
            token: token,
          ),
          rawPathParams: {
            'uid': uid,
            'token': token,
          },
          initialChildren: children,
        );

  static const String name = 'AccountActivationRoute';

  static const _i31.PageInfo<AccountActivationRouteArgs> page =
      _i31.PageInfo<AccountActivationRouteArgs>(name);
}

class AccountActivationRouteArgs {
  const AccountActivationRouteArgs({
    this.key,
    required this.uid,
    required this.token,
  });

  final _i32.Key? key;

  final String uid;

  final String token;

  @override
  String toString() {
    return 'AccountActivationRouteArgs{key: $key, uid: $uid, token: $token}';
  }
}

/// generated route for
/// [_i3.AnonymousRouterPage]
class AnonymousRouterRoute extends _i31.PageRouteInfo<void> {
  const AnonymousRouterRoute({List<_i31.PageRouteInfo>? children})
      : super(
          AnonymousRouterRoute.name,
          initialChildren: children,
        );

  static const String name = 'AnonymousRouterRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i4.AnswerQuestionPage]
class AnswerQuestionRoute extends _i31.PageRouteInfo<AnswerQuestionRouteArgs> {
  AnswerQuestionRoute({
    _i32.Key? key,
    required _i33.Question question,
    required List<_i33.Interlocutor> allConnectedInterlocutors,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          AnswerQuestionRoute.name,
          args: AnswerQuestionRouteArgs(
            key: key,
            question: question,
            allConnectedInterlocutors: allConnectedInterlocutors,
          ),
          initialChildren: children,
        );

  static const String name = 'AnswerQuestionRoute';

  static const _i31.PageInfo<AnswerQuestionRouteArgs> page =
      _i31.PageInfo<AnswerQuestionRouteArgs>(name);
}

class AnswerQuestionRouteArgs {
  const AnswerQuestionRouteArgs({
    this.key,
    required this.question,
    required this.allConnectedInterlocutors,
  });

  final _i32.Key? key;

  final _i33.Question question;

  final List<_i33.Interlocutor> allConnectedInterlocutors;

  @override
  String toString() {
    return 'AnswerQuestionRouteArgs{key: $key, question: $question, allConnectedInterlocutors: $allConnectedInterlocutors}';
  }
}

/// generated route for
/// [_i5.AuthRouter]
class AuthRouter extends _i31.PageRouteInfo<void> {
  const AuthRouter({List<_i31.PageRouteInfo>? children})
      : super(
          AuthRouter.name,
          initialChildren: children,
        );

  static const String name = 'AuthRouter';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i6.CreateInvitationPage]
class CreateInvitationRoute extends _i31.PageRouteInfo<void> {
  const CreateInvitationRoute({List<_i31.PageRouteInfo>? children})
      : super(
          CreateInvitationRoute.name,
          initialChildren: children,
        );

  static const String name = 'CreateInvitationRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i7.EmptyRouterPage]
class EmptyRouterRoute extends _i31.PageRouteInfo<void> {
  const EmptyRouterRoute({List<_i31.PageRouteInfo>? children})
      : super(
          EmptyRouterRoute.name,
          initialChildren: children,
        );

  static const String name = 'EmptyRouterRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i8.FriendsRouterPage]
class FriendsRouterRoute extends _i31.PageRouteInfo<void> {
  const FriendsRouterRoute({List<_i31.PageRouteInfo>? children})
      : super(
          FriendsRouterRoute.name,
          initialChildren: children,
        );

  static const String name = 'FriendsRouterRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i9.HomeFeedPage]
class HomeFeedRoute extends _i31.PageRouteInfo<void> {
  const HomeFeedRoute({List<_i31.PageRouteInfo>? children})
      : super(
          HomeFeedRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeFeedRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i10.HomeFeedRouter]
class HomeFeedRouter extends _i31.PageRouteInfo<void> {
  const HomeFeedRouter({List<_i31.PageRouteInfo>? children})
      : super(
          HomeFeedRouter.name,
          initialChildren: children,
        );

  static const String name = 'HomeFeedRouter';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i11.HomeTabsRouterPage]
class HomeTabsRouterRoute extends _i31.PageRouteInfo<void> {
  const HomeTabsRouterRoute({List<_i31.PageRouteInfo>? children})
      : super(
          HomeTabsRouterRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeTabsRouterRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i12.LandingPage]
class LandingRoute extends _i31.PageRouteInfo<void> {
  const LandingRoute({List<_i31.PageRouteInfo>? children})
      : super(
          LandingRoute.name,
          initialChildren: children,
        );

  static const String name = 'LandingRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i13.LoginPage]
class LoginRoute extends _i31.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i32.Key? key,
    void Function()? onLoginSuccessCallback,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          LoginRoute.name,
          args: LoginRouteArgs(
            key: key,
            onLoginSuccessCallback: onLoginSuccessCallback,
          ),
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const _i31.PageInfo<LoginRouteArgs> page =
      _i31.PageInfo<LoginRouteArgs>(name);
}

class LoginRouteArgs {
  const LoginRouteArgs({
    this.key,
    this.onLoginSuccessCallback,
  });

  final _i32.Key? key;

  final void Function()? onLoginSuccessCallback;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, onLoginSuccessCallback: $onLoginSuccessCallback}';
  }
}

/// generated route for
/// [_i14.ManuallyAcceptInvitationRoute]
class ManuallyAcceptInvitationRoute extends _i31.PageRouteInfo<void> {
  const ManuallyAcceptInvitationRoute({List<_i31.PageRouteInfo>? children})
      : super(
          ManuallyAcceptInvitationRoute.name,
          initialChildren: children,
        );

  static const String name = 'ManuallyAcceptInvitationRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i15.MultipurposeQuestionThreadsPage]
class MultipurposeQuestionThreadsRoute
    extends _i31.PageRouteInfo<MultipurposeQuestionThreadsRouteArgs> {
  MultipurposeQuestionThreadsRoute({
    _i32.Key? key,
    String? chatThreadId,
    required _i25.QuestionThreadsPageType questionThreadsPageType,
    required _i33.Interlocutor currentInterlocutor,
    required List<_i33.Interlocutor> allInterlocutors,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          MultipurposeQuestionThreadsRoute.name,
          args: MultipurposeQuestionThreadsRouteArgs(
            key: key,
            chatThreadId: chatThreadId,
            questionThreadsPageType: questionThreadsPageType,
            currentInterlocutor: currentInterlocutor,
            allInterlocutors: allInterlocutors,
          ),
          rawPathParams: {'chatThread': chatThreadId},
          initialChildren: children,
        );

  static const String name = 'MultipurposeQuestionThreadsRoute';

  static const _i31.PageInfo<MultipurposeQuestionThreadsRouteArgs> page =
      _i31.PageInfo<MultipurposeQuestionThreadsRouteArgs>(name);
}

class MultipurposeQuestionThreadsRouteArgs {
  const MultipurposeQuestionThreadsRouteArgs({
    this.key,
    this.chatThreadId,
    required this.questionThreadsPageType,
    required this.currentInterlocutor,
    required this.allInterlocutors,
  });

  final _i32.Key? key;

  final String? chatThreadId;

  final _i25.QuestionThreadsPageType questionThreadsPageType;

  final _i33.Interlocutor currentInterlocutor;

  final List<_i33.Interlocutor> allInterlocutors;

  @override
  String toString() {
    return 'MultipurposeQuestionThreadsRouteArgs{key: $key, chatThreadId: $chatThreadId, questionThreadsPageType: $questionThreadsPageType, currentInterlocutor: $currentInterlocutor, allInterlocutors: $allInterlocutors}';
  }
}

/// generated route for
/// [_i16.MultipurposeQuestionsPage]
class MultipurposeQuestionsRoute
    extends _i31.PageRouteInfo<MultipurposeQuestionsRouteArgs> {
  MultipurposeQuestionsRoute({
    _i32.Key? key,
    String? chatThreadId,
    required _i25.QuestionsPageType questionsPageType,
    required _i33.Interlocutor currentInterlocutor,
    required List<_i33.Interlocutor> otherInterlocutors,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          MultipurposeQuestionsRoute.name,
          args: MultipurposeQuestionsRouteArgs(
            key: key,
            chatThreadId: chatThreadId,
            questionsPageType: questionsPageType,
            currentInterlocutor: currentInterlocutor,
            otherInterlocutors: otherInterlocutors,
          ),
          rawPathParams: {'chatThread': chatThreadId},
          initialChildren: children,
        );

  static const String name = 'MultipurposeQuestionsRoute';

  static const _i31.PageInfo<MultipurposeQuestionsRouteArgs> page =
      _i31.PageInfo<MultipurposeQuestionsRouteArgs>(name);
}

class MultipurposeQuestionsRouteArgs {
  const MultipurposeQuestionsRouteArgs({
    this.key,
    this.chatThreadId,
    required this.questionsPageType,
    required this.currentInterlocutor,
    required this.otherInterlocutors,
  });

  final _i32.Key? key;

  final String? chatThreadId;

  final _i25.QuestionsPageType questionsPageType;

  final _i33.Interlocutor currentInterlocutor;

  final List<_i33.Interlocutor> otherInterlocutors;

  @override
  String toString() {
    return 'MultipurposeQuestionsRouteArgs{key: $key, chatThreadId: $chatThreadId, questionsPageType: $questionsPageType, currentInterlocutor: $currentInterlocutor, otherInterlocutors: $otherInterlocutors}';
  }
}

/// generated route for
/// [_i17.PasswordResetConfirmPage]
class PasswordResetConfirmRoute
    extends _i31.PageRouteInfo<PasswordResetConfirmRouteArgs> {
  PasswordResetConfirmRoute({
    _i32.Key? key,
    required String uid,
    required String token,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          PasswordResetConfirmRoute.name,
          args: PasswordResetConfirmRouteArgs(
            key: key,
            uid: uid,
            token: token,
          ),
          rawPathParams: {
            'uid': uid,
            'token': token,
          },
          initialChildren: children,
        );

  static const String name = 'PasswordResetConfirmRoute';

  static const _i31.PageInfo<PasswordResetConfirmRouteArgs> page =
      _i31.PageInfo<PasswordResetConfirmRouteArgs>(name);
}

class PasswordResetConfirmRouteArgs {
  const PasswordResetConfirmRouteArgs({
    this.key,
    required this.uid,
    required this.token,
  });

  final _i32.Key? key;

  final String uid;

  final String token;

  @override
  String toString() {
    return 'PasswordResetConfirmRouteArgs{key: $key, uid: $uid, token: $token}';
  }
}

/// generated route for
/// [_i18.PasswordResetPage]
class PasswordResetRoute extends _i31.PageRouteInfo<PasswordResetRouteArgs> {
  PasswordResetRoute({
    _i32.Key? key,
    bool cameFromLogin = false,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          PasswordResetRoute.name,
          args: PasswordResetRouteArgs(
            key: key,
            cameFromLogin: cameFromLogin,
          ),
          initialChildren: children,
        );

  static const String name = 'PasswordResetRoute';

  static const _i31.PageInfo<PasswordResetRouteArgs> page =
      _i31.PageInfo<PasswordResetRouteArgs>(name);
}

class PasswordResetRouteArgs {
  const PasswordResetRouteArgs({
    this.key,
    this.cameFromLogin = false,
  });

  final _i32.Key? key;

  final bool cameFromLogin;

  @override
  String toString() {
    return 'PasswordResetRouteArgs{key: $key, cameFromLogin: $cameFromLogin}';
  }
}

/// generated route for
/// [_i19.PeopleListPage]
class PeopleListRoute extends _i31.PageRouteInfo<void> {
  const PeopleListRoute({List<_i31.PageRouteInfo>? children})
      : super(
          PeopleListRoute.name,
          initialChildren: children,
        );

  static const String name = 'PeopleListRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i20.PeopleRouter]
class PeopleRouter extends _i31.PageRouteInfo<void> {
  const PeopleRouter({List<_i31.PageRouteInfo>? children})
      : super(
          PeopleRouter.name,
          initialChildren: children,
        );

  static const String name = 'PeopleRouter';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i21.ProfileEditPage]
class ProfileEditRoute extends _i31.PageRouteInfo<void> {
  const ProfileEditRoute({List<_i31.PageRouteInfo>? children})
      : super(
          ProfileEditRoute.name,
          initialChildren: children,
        );

  static const String name = 'ProfileEditRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i22.ProfilePage]
class ProfileRoute extends _i31.PageRouteInfo<void> {
  const ProfileRoute({List<_i31.PageRouteInfo>? children})
      : super(
          ProfileRoute.name,
          initialChildren: children,
        );

  static const String name = 'ProfileRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i23.ProfileRouter]
class ProfileRouter extends _i31.PageRouteInfo<void> {
  const ProfileRouter({List<_i31.PageRouteInfo>? children})
      : super(
          ProfileRouter.name,
          initialChildren: children,
        );

  static const String name = 'ProfileRouter';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i24.QuestionChatsPage]
class QuestionChatsRoute extends _i31.PageRouteInfo<QuestionChatsRouteArgs> {
  QuestionChatsRoute({
    _i32.Key? key,
    required String chatThreadId,
    required String questionThreadId,
    required _i33.Question question,
    required List<_i33.Interlocutor> interlocutors,
    required void Function() onSetToSeenSucceeded,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          QuestionChatsRoute.name,
          args: QuestionChatsRouteArgs(
            key: key,
            chatThreadId: chatThreadId,
            questionThreadId: questionThreadId,
            question: question,
            interlocutors: interlocutors,
            onSetToSeenSucceeded: onSetToSeenSucceeded,
          ),
          rawPathParams: {
            'chatThread': chatThreadId,
            'questionThread': questionThreadId,
          },
          initialChildren: children,
        );

  static const String name = 'QuestionChatsRoute';

  static const _i31.PageInfo<QuestionChatsRouteArgs> page =
      _i31.PageInfo<QuestionChatsRouteArgs>(name);
}

class QuestionChatsRouteArgs {
  const QuestionChatsRouteArgs({
    this.key,
    required this.chatThreadId,
    required this.questionThreadId,
    required this.question,
    required this.interlocutors,
    required this.onSetToSeenSucceeded,
  });

  final _i32.Key? key;

  final String chatThreadId;

  final String questionThreadId;

  final _i33.Question question;

  final List<_i33.Interlocutor> interlocutors;

  final void Function() onSetToSeenSucceeded;

  @override
  String toString() {
    return 'QuestionChatsRouteArgs{key: $key, chatThreadId: $chatThreadId, questionThreadId: $questionThreadId, question: $question, interlocutors: $interlocutors, onSetToSeenSucceeded: $onSetToSeenSucceeded}';
  }
}

/// generated route for
/// [_i25.QuestionThreadsPage]
class QuestionThreadsRoute
    extends _i31.PageRouteInfo<QuestionThreadsRouteArgs> {
  QuestionThreadsRoute({
    _i32.Key? key,
    required String chatThreadId,
    required _i33.Interlocutor currentInterlocutor,
    required List<_i33.Interlocutor> otherInterlocutors,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          QuestionThreadsRoute.name,
          args: QuestionThreadsRouteArgs(
            key: key,
            chatThreadId: chatThreadId,
            currentInterlocutor: currentInterlocutor,
            otherInterlocutors: otherInterlocutors,
          ),
          rawPathParams: {'chatThread': chatThreadId},
          initialChildren: children,
        );

  static const String name = 'QuestionThreadsRoute';

  static const _i31.PageInfo<QuestionThreadsRouteArgs> page =
      _i31.PageInfo<QuestionThreadsRouteArgs>(name);
}

class QuestionThreadsRouteArgs {
  const QuestionThreadsRouteArgs({
    this.key,
    required this.chatThreadId,
    required this.currentInterlocutor,
    required this.otherInterlocutors,
  });

  final _i32.Key? key;

  final String chatThreadId;

  final _i33.Interlocutor currentInterlocutor;

  final List<_i33.Interlocutor> otherInterlocutors;

  @override
  String toString() {
    return 'QuestionThreadsRouteArgs{key: $key, chatThreadId: $chatThreadId, currentInterlocutor: $currentInterlocutor, otherInterlocutors: $otherInterlocutors}';
  }
}

/// generated route for
/// [_i26.QuestionThreadsRouter]
class QuestionThreadsRouter
    extends _i31.PageRouteInfo<QuestionThreadsRouterArgs> {
  QuestionThreadsRouter({
    _i32.Key? key,
    required String questionThreadId,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          QuestionThreadsRouter.name,
          args: QuestionThreadsRouterArgs(
            key: key,
            questionThreadId: questionThreadId,
          ),
          rawPathParams: {'questionThread': questionThreadId},
          initialChildren: children,
        );

  static const String name = 'QuestionThreadsRouter';

  static const _i31.PageInfo<QuestionThreadsRouterArgs> page =
      _i31.PageInfo<QuestionThreadsRouterArgs>(name);
}

class QuestionThreadsRouterArgs {
  const QuestionThreadsRouterArgs({
    this.key,
    required this.questionThreadId,
  });

  final _i32.Key? key;

  final String questionThreadId;

  @override
  String toString() {
    return 'QuestionThreadsRouterArgs{key: $key, questionThreadId: $questionThreadId}';
  }
}

/// generated route for
/// [_i27.QuestionsPage]
class QuestionsRoute extends _i31.PageRouteInfo<void> {
  const QuestionsRoute({List<_i31.PageRouteInfo>? children})
      : super(
          QuestionsRoute.name,
          initialChildren: children,
        );

  static const String name = 'QuestionsRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i28.SignUpPage]
class SignUpRoute extends _i31.PageRouteInfo<SignUpRouteArgs> {
  SignUpRoute({
    _i32.Key? key,
    bool cameFromLogin = false,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          SignUpRoute.name,
          args: SignUpRouteArgs(
            key: key,
            cameFromLogin: cameFromLogin,
          ),
          initialChildren: children,
        );

  static const String name = 'SignUpRoute';

  static const _i31.PageInfo<SignUpRouteArgs> page =
      _i31.PageInfo<SignUpRouteArgs>(name);
}

class SignUpRouteArgs {
  const SignUpRouteArgs({
    this.key,
    this.cameFromLogin = false,
  });

  final _i32.Key? key;

  final bool cameFromLogin;

  @override
  String toString() {
    return 'SignUpRouteArgs{key: $key, cameFromLogin: $cameFromLogin}';
  }
}

/// generated route for
/// [_i29.SplashPage]
class SplashRoute extends _i31.PageRouteInfo<void> {
  const SplashRoute({List<_i31.PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const _i31.PageInfo<void> page = _i31.PageInfo<void>(name);
}

/// generated route for
/// [_i30.UserTermsPage]
class UserTermsRoute extends _i31.PageRouteInfo<UserTermsRouteArgs> {
  UserTermsRoute({
    _i32.Key? key,
    bool cameFromSignup = false,
    List<_i31.PageRouteInfo>? children,
  }) : super(
          UserTermsRoute.name,
          args: UserTermsRouteArgs(
            key: key,
            cameFromSignup: cameFromSignup,
          ),
          initialChildren: children,
        );

  static const String name = 'UserTermsRoute';

  static const _i31.PageInfo<UserTermsRouteArgs> page =
      _i31.PageInfo<UserTermsRouteArgs>(name);
}

class UserTermsRouteArgs {
  const UserTermsRouteArgs({
    this.key,
    this.cameFromSignup = false,
  });

  final _i32.Key? key;

  final bool cameFromSignup;

  @override
  String toString() {
    return 'UserTermsRouteArgs{key: $key, cameFromSignup: $cameFromSignup}';
  }
}
