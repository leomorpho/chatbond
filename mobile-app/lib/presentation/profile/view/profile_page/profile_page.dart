import 'package:auto_route/auto_route.dart';
import 'package:chatbond/bootstrap.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/authentication/bloc/authentication_bloc.dart';
import 'package:chatbond/presentation/chats/chats/question_threads_page/main/question_threads_page.dart';
import 'package:chatbond/presentation/profile/view/profile_page/cubit/profile_page_cubit.dart';
import 'package:chatbond/presentation/profile/view/shared_widgets/profile_header.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/menu_item.dart';
import 'package:chatbond/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfilePageCubit>(
      create: (context) => ProfilePageCubit(
        context.read<UserRepo>(),
        context.read<ChatThreadsRepo>(),
        context.read<QuestionsRepo>(),
        context.read<ChatProvider>().numTotalNotificationsController.stream,
      ),
      child: const ProfilePageView(),
    );
  }
}

class ProfilePageView extends StatefulWidget {
  const ProfilePageView({
    super.key,
  });

  @override
  State<ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<ProfilePageView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // when the app returns from the background
      context.read<ProfilePageCubit>().fetchUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MaxWidthView(
        child: BlocBuilder<ProfilePageCubit, ProfilePageState>(
          builder: (context, state) {
            if (state is ProfilePageLoadSuccess) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 30),
                    ProfileHeaderWidget(
                      email: state.user.email,
                      username: state.user.name,
                      onEditClicked: () {}, // image edit not supported for MVP
                    ),
                    // TODO: could have button to upgrade to Plus. Only show Subscription if already subscribed.

                    const SizedBox(
                      height: 10,
                    ),
                    MenuItem(
                      iconData: Icons.chat,
                      titleWidget: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '${state.waitingOnYouQuestionCount} Pending for you',
                          ),
                          if (state.waitingOnYouQuestionCount > 0)
                            Container(
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
                                state.waitingOnYouQuestionCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        context.router.push(
                          MultipurposeQuestionThreadsRoute(
                            questionThreadsPageType: QuestionThreadsPageType
                                .waitingForCurrUserForAllChatThreads,
                            currentInterlocutor:
                                getIt.get<GlobalState>().currentInterlocutor!,
                            allInterlocutors: state.allInterlocutors,
                          ),
                        );
                      },
                    ),
                    MenuItem(
                      iconData: Icons.hourglass_top,
                      title:
                          '${state.waitingOnOthersQuestionCount} Pending on others', // Do not allow navigation if there are 0 items
                      onTap: () {
                        context.router.push(
                          MultipurposeQuestionThreadsRoute(
                            questionThreadsPageType: QuestionThreadsPageType
                                .waitingOnOthersForAllChatThreads,
                            currentInterlocutor:
                                getIt.get<GlobalState>().currentInterlocutor!,
                            allInterlocutors: state.allInterlocutors,
                          ),
                        );
                      },
                    ),
                    MenuItem(
                      iconData: Icons.edit_document,
                      title:
                          '${state.draftsCount} Drafts', // Do not allow navigation if there are 0 items
                      onTap: () {
                        context.router.push(
                          MultipurposeQuestionsRoute(
                            questionsPageType:
                                QuestionsPageType.draftsForAllChatThreads,
                            currentInterlocutor:
                                getIt.get<GlobalState>().currentInterlocutor!,
                            otherInterlocutors: getIt
                                .get<GlobalState>()
                                .connectedInterlocutors!,
                          ),
                        );
                      },
                    ),
                    MenuItem(
                      iconData: Icons.favorite,
                      title:
                          '${state.favoritedQuestionsCount} Favorites', // Do not allow navigation if there are 0 items
                      onTap: () {
                        context.router.push(
                          MultipurposeQuestionsRoute(
                            questionsPageType: QuestionsPageType.favorites,
                            currentInterlocutor:
                                getIt.get<GlobalState>().currentInterlocutor!,
                            otherInterlocutors: getIt
                                .get<GlobalState>()
                                .connectedInterlocutors!,
                          ),
                        );
                      },
                    ),
                    const Divider(
                      height: 20,
                    ),
                    // MenuItem(
                    //   iconData: Icons.credit_card,
                    //   title: 'Upgrade to Plus',
                    //   onTap: () {
                    //     context.pushRoute(const ProfileEditRoute());
                    //   }, // TODO
                    // ),
                    MenuItem(
                      iconData: Icons.person,
                      title: 'Edit Profile',
                      onTap: () {
                        context.pushRoute(const ProfileEditRoute());
                      }, // TODO
                    ),
                    MenuItem(
                      iconData: Icons.logout,
                      title: 'Logout',
                      onTap: () {
                        context
                            .read<AuthenticationBloc>()
                            .add(AuthenticationLogoutRequested());
                        // OneSignal.logout();
                        AutoRouter.of(context).replaceAll(
                          [const AnonymousRouterRoute(), LoginRoute()],
                        );
                      },
                    ),
                  ],
                ),
              );
            }
            if (state is ProfilePageLoadFailure) {
              return const Text('Failed to load user data');
            }
            return const CircularProgressIndicator(); // loading state
          },
        ),
      ),
    );
  }
}
