import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/constants.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/presentation/chats/chats/chat_threads_page/chat_threads_bloc/chat_threads_bloc.dart';
import 'package:chatbond/presentation/chats/chats/chat_threads_page/invitations_cubit.dart';
import 'package:chatbond/presentation/chats/invitations/create_invitation/create_invitation_page.dart';
import 'package:chatbond/presentation/shared_widgets/chat_thread_card.dart';
import 'package:chatbond/presentation/shared_widgets/invitation_widget.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond/utils.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';

@RoutePage()
class PeopleListPage extends StatefulWidget {
  const PeopleListPage({
    super.key,
  });

  @override
  State<PeopleListPage> createState() => _PeopleListPageState();
}

class _PeopleListPageState extends State<PeopleListPage>
    with WidgetsBindingObserver {
  late VisibilityChangeNotifier _visibilityChangeNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _visibilityChangeNotifier = VisibilityChangeNotifier(
      thresholdInSeconds: visibilityChangeNotifierTimespan,
      onThresholdExceeded: () async {
        // Replace this line with the code you want to execute when threshold is exceeded
        logDebug('refocusing on tab, refreshing chat threads...');
        await context.read<ChatThreadsRepo>().getAllChatThreads();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visibilityChangeNotifier.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// Reload entire page on app on app moving back into foreground. This is
    /// for mobile only.
    // TODO: does not work in browser.
    if (state == AppLifecycleState.resumed) {
      // when the app returns from the background
      context.read<ChatThreadsRepo>().getAllChatThreads();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MaxWidthView(
        child: const Padding(
          padding: EdgeInsets.all(30),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Text(
                  'Chats',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              SliverToBoxAdapter(
                child: ChatThreadList(
                  cardBorderRadius: 16,
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 24),
                    Text(
                      'Invitations',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: InvitationsWidget(
                  cardBorderRadius: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatThreadList extends StatelessWidget {
  const ChatThreadList({
    super.key,
    this.cardBorderRadius = 24,
  });
  final double cardBorderRadius;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatThreadsBloc, ChatThreadsState>(
      // buildWhen: (prev, state) => prev.runtimeType != state.runtimeType,
      builder: (context, state) {
        switch (state.status) {
          case ChatThreadsStatus.loading:
            return Text('${LocaleKeys.loading.tr().toCapitalized()}...');
          case ChatThreadsStatus.loaded:
            if (state.chatThreads.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      LocaleKeys.youDoNotAppearToHaveChatThreadsYet
                          .tr()
                          .toCapitalized(),
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: state.chatThreads.length,
              itemBuilder: (BuildContext context, int index) {
                // TODO: kinda disgusting, to revise one day
                final otherInterlocutors = filterInterlocutors(
                  interlocutorsToFilter: state.chatThreads[index].interlocutors,
                  interlocutorToExclude: state.chatThreads[index].owner,
                )
                    .where(
                      (element) => state.chatThreads[index].interlocutors
                          .contains(element),
                    )
                    .toList();

                return ChatThreadCard(
                  interlocutor: otherInterlocutors[0],
                  updatedAt: DateTime.parse(state.chatThreads[index].updatedAt),
                  numUnseenMessages:
                      state.chatThreads[index].numNewUnseenMessages ?? 0,
                  onWidgetTap: () {
                    // Navigate to QuestionThreadsPage with the selected chatThread
                    context.router.push(
                      QuestionThreadsRoute(
                        chatThreadId: state.chatThreads[index].id,
                        currentInterlocutor:
                            getIt.get<GlobalState>().currentInterlocutor!,
                        otherInterlocutors: otherInterlocutors,
                      ),
                    );
                  },
                  cardBorderRadius: cardBorderRadius,
                );
              },
            );

          case ChatThreadsStatus.failure:
            return Text('${LocaleKeys.failedToLoad.tr().toCapitalized()} '
                '${LocaleKeys.chatThreads.tr()}');
        }
      },
    );
  }
}

class InvitationsWidget extends StatelessWidget {
  const InvitationsWidget({super.key, this.cardBorderRadius = 24});
  final double cardBorderRadius;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvitationsCubit, InvitationsState>(
      builder: (context, state) {
        if (state is InvitationsLoaded) {
          return InvitationGrid(
            invitations: state.invitations,
            cardBorderRadius: cardBorderRadius,
          );
        }
        return const LoadingDialog();
      },
    );
  }
}

class InvitationGrid extends StatelessWidget {
  const InvitationGrid({
    super.key,
    required this.invitations,
    this.cardBorderRadius = 24,
  });
  final List<Invitation> invitations;
  final double cardBorderRadius;
  @override
  Widget build(BuildContext context) {
    // Determine the number of columns based on screen size
    final columns =
        ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 3 : 2;

    final children = List<Widget>.from(
      invitations.map(
        (invitation) => InvididualInvitationsWidget(
          invitation: invitation,
          cardBorderRadius: cardBorderRadius,
        ),
      ),
    )

      // Append the InvitationsCRUDWidget to the list of children
      ..add(
        InvitationsCRUDWidget(
          // inviteTitle: LocaleKeys.createNewConversation.tr().toTitleCase(),
          inviteButtonLabel: LocaleKeys.inviteSomeone.tr().toCapitalized(),
          acceptInviteButtonLabel:
              LocaleKeys.acceptInvitationManually.tr().toTitleCase(),
          onCreateInvitePressed: () {
            AutoRouter.of(context).push(const CreateInvitationRoute());
          },
          onManuallyAcceptInvitePressed: () {
            context.pushRoute(const ManuallyAcceptInvitationRoute());
          },
        ),
      );

    return GridView.custom(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
      ),
      childrenDelegate: SliverChildListDelegate(
        children,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
}

class InvididualInvitationsWidget extends StatelessWidget {
  const InvididualInvitationsWidget({
    super.key,
    required this.invitation,
    this.cardBorderRadius = 16,
  });
  final Invitation invitation;
  final double cardBorderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showInvitationDetails(
        context,
        invitation,
        context.read<InvitationsCubit>(),
      ),
      child: Card(
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(
              invitation.inviteeName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _showInvitationDetails(
    BuildContext context,
    Invitation invitation,
    InvitationsCubit invitationCubit,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Invitation Details', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              children: [InvitationInfoWidget(invitation: invitation)],
            ),
          ),
          actions: <Widget>[
            Builder(
              builder: (context) {
                return TextButton(
                  child: const Text('Delete'),
                  onPressed: () async {
                    invitationCubit.deleteInvitation(
                      invitation,
                      callBackend: true,
                    );
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
