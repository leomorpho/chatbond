import 'package:auto_route/auto_route.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/realtime_repo/realtime_repo.dart';
import 'package:chatbond/presentation/chats/chats/question_chats_page/question_chats_page_cubit/question_chats_page_cubit.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

@RoutePage()
class QuestionChatsPage extends StatelessWidget {
  const QuestionChatsPage({
    super.key,
    @PathParam('chatThread') required this.chatThreadId,
    @PathParam('questionThread') required this.questionThreadId,
    required this.question, // TODO: remove dependence on this
    required this.interlocutors, // TODO: remove dependence on this
    required this.onSetToSeenSucceeded,
  });
  final Question question;
  final String questionThreadId;
  final String chatThreadId;
  final List<Interlocutor> interlocutors;
  final void Function() onSetToSeenSucceeded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestionChatsPageCubit(
        question: question,
        chatThreadsRepo: context.read<ChatThreadsRepo>(),
        interlocutors: interlocutors,
        onSetToSeenSucceeded: onSetToSeenSucceeded,
        realtimeRepo: context.read<RealtimeRepo>(),
      )..loadQuestionChats(questionThreadId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Question Chats'),
        ),
        body: MaxWidthView(
          child: BlocBuilder<QuestionChatsPageCubit, QuestionChatsPageState>(
            builder: (context, state) {
              if (state is QuestionChatsPageLoaded) {
                return Chat(
                  messages: state.messagesByThreadId[questionThreadId] ?? [],
                  // onAttachmentPressed: _handleAttachmentPressed,
                  // onMessageTap: _handleMessageTap,
                  // onPreviewDataFetched: _handlePreviewDataFetched,
                  onSendPressed: context
                      .read<QuestionChatsPageCubit>()
                      .addQuestionChatForCurrentUserAsAuthor,
                  // showUserAvatars: true,
                  showUserNames: true,
                  user: state.user,
                  dateIsUtc: true,
                  groupMessagesThreshold: 30 * 60000, // 30 minutes in ms
                  inputOptions: const InputOptions(
                    sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                  ),
                  theme: DefaultChatTheme(
                    backgroundColor: Theme.of(context).colorScheme.background,
                  ),
                  systemMessageBuilder: (types.SystemMessage message) {
                    return Column(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
                          color: Theme.of(context).colorScheme.primaryContainer,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  message.text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        )
                      ],
                    );
                  },

                  // bubbleBuilder: (
                  //   Widget child, {
                  //   required chat_types.Message message,
                  //   required bool nextMessageInGroup,
                  // }) =>
                  //     Bubble(
                  //   color: message.author.id == chatbondUser
                  //       ? const Color.fromARGB(255, 185, 134, 15)
                  //       : state.user.id != message.author.id
                  //           ? const Color.fromARGB(255, 63, 63, 103)
                  //           : const Color.fromARGB(255, 96, 232, 86),
                  //   margin: nextMessageInGroup
                  //       ? const BubbleEdges.symmetric(horizontal: 3)
                  //       : null,
                  //   nip: message.author.id == chatbondUser || nextMessageInGroup
                  //       ? BubbleNip.no
                  //       : state.user.id != message.author.id
                  //           ? BubbleNip.leftBottom
                  //           : BubbleNip.rightBottom,
                  //   alignment: message.author.id == chatbondUser
                  //       ? Alignment.centerRight
                  //       : null,
                  //   elevation: message.author.id == chatbondUser ? 5 : null,
                  //   stick: message.author.id == chatbondUser ? false : null,
                  //   child: child,
                  // ),
                  // TODO: see here for scroll to first unread: https://docs.flyer.chat/flutter/chat-ui/advanced-usage
                  // scrollToUnreadOptions: const ScrollToUnreadOptions(
                  //     lastReadMessageId: 'lastReadMessageId',
                  //     scrollOnOpen: true,
                  //   )
                );
              } else if (state is QuestionChatsPageError) {
                return Center(child: Text(state.message));
              } else {
                return const Center(child: LoadingDialog());
              }
            },
          ),
        ),
      ),
    );
  }
}

// Widget _bubbleBuilder(
//   Widget child, {
//   required message,
//   required nextMessageInGroup,
// }) =>
//     Bubble(
//       child: child,
//       color: _user.id != message.author.id ||
//               message.type == types.MessageType.image
//           ? const Color(0xfff5f5f7)
//           : const Color(0xff6f61e8),
//       margin: nextMessageInGroup
//           ? const BubbleEdges.symmetric(horizontal: 6)
//           : null,
//       nip: nextMessageInGroup
//           ? BubbleNip.no
//           : _user.id != message.author.id
//               ? BubbleNip.leftBottom
//               : BubbleNip.rightBottom,
//     );
