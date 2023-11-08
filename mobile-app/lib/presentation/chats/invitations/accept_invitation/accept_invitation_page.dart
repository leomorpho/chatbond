import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/chats/invitations/accept_invitation/accept_invitation_cubit/accept_invitation_cubit.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond/utils.dart';

@RoutePage()
class AcceptInvitationRoute extends StatelessWidget {
  const AcceptInvitationRoute({
    super.key,
    @PathParam('token') required this.token,
  });

  final String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accept Invitation'),
        centerTitle: true,
      ),
      body: MaxWidthView(
        child: BlocProvider(
          create: (context) => AcceptInvitationCubit(
              invitationsRepo: context.read<InvitationsRepo>(),
              chatsRepo: context.read<ChatThreadsRepo>())
            ..acceptInvitation(token),
          child: BlocBuilder<AcceptInvitationCubit, AcceptInvitationState>(
            builder: (context, state) {
              if (state.status == InvitationStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'An error occurred while accepting the invitation.',
                      ),
                      const SizedBox(height: 16),
                      // TODO: add input field to manually submit token
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<AcceptInvitationCubit>()
                              .acceptInvitation(token);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state.status == InvitationStatus.success) {
                final otherInterlocutors = filterInterlocutors(
                  interlocutorsToFilter: state.chatThread!.interlocutors,
                  interlocutorToExclude: state.chatThread!.owner,
                );
                final interlocutorNames =
                    createNameStrFromInterlocutors(otherInterlocutors);

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'You are now connected to $interlocutorNames',
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.router.popAndPush(
                            QuestionThreadsRoute(
                              chatThreadId: state.chatThread!.id,
                              currentInterlocutor:
                                  getIt.get<GlobalState>().currentInterlocutor!,
                              otherInterlocutors: otherInterlocutors,
                            ),
                          );
                        },
                        child:
                            const Text('Go to the corresponding chat thread'),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(
                  child: LoadingDialog(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
