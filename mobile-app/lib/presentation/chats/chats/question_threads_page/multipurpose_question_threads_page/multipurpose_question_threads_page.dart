import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/presentation/chats/chats/question_threads_page/main/question_threads_page.dart';
import 'package:chatbond/presentation/chats/chats/question_threads_page/multipurpose_question_threads_page/cubit/multipurpose_question_threads_page_cubit.dart';
import 'package:chatbond/presentation/shared_widgets/bottom_loader.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/question_card.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond/utils.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

@RoutePage()
class MultipurposeQuestionThreadsPage extends StatelessWidget {
  const MultipurposeQuestionThreadsPage({
    super.key,
    @PathParam('chatThread') this.chatThreadId,
    required this.questionThreadsPageType,
    required this.currentInterlocutor,
    required this.allInterlocutors,
  });

  final String? chatThreadId;
  final Interlocutor currentInterlocutor;
  final List<Interlocutor> allInterlocutors;
  final QuestionThreadsPageType questionThreadsPageType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MultipurposeQuestionThreadsPageCubit(
        chatThreadsRepo: context.read<ChatThreadsRepo>(),
        questionsRepo: context.read<QuestionsRepo>(),
        questionThreadsPageType: questionThreadsPageType,
        chatThreadId: chatThreadId,
        allInterlocutors: allInterlocutors,
      )..loadQuestionThreads(chatThreadId),
      child: MultipurposeQuestionThreadsPageView(
        questionThreadsPageType: questionThreadsPageType,
        chatThreadId: chatThreadId,
        currentInterlocutor: currentInterlocutor,
      ),
    );
  }
}

class MultipurposeQuestionThreadsPageView extends StatefulWidget {
  const MultipurposeQuestionThreadsPageView({
    super.key,
    required this.questionThreadsPageType,
    this.chatThreadId,
    this.currentInterlocutor,
  });

  final QuestionThreadsPageType questionThreadsPageType;
  final String? chatThreadId;
  final Interlocutor? currentInterlocutor;

  @override
  MultipurposeQuestionThreadsPageViewState createState() =>
      MultipurposeQuestionThreadsPageViewState();
}

class MultipurposeQuestionThreadsPageViewState
    extends State<MultipurposeQuestionThreadsPageView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController
      ..addListener(_onScroll)
      ..addListener(() {});
  }

  String getAppBarText(List<Interlocutor> interlocutors) {
    final otherInterlocutor = widget.currentInterlocutor == null
        ? ''
        : createNameStrFromInterlocutors(
            filterInterlocutors(
              interlocutorsToFilter: interlocutors,
              interlocutorToExclude: widget.currentInterlocutor,
            ),
          );

    switch (widget.questionThreadsPageType) {
      case QuestionThreadsPageType
            .waitingForCurrUserForSpecificChatThread: // TODO
        return '$otherInterlocutor is Waiting on You';

      case QuestionThreadsPageType.waitingOnOthersForSpecificChatThread:
        return 'Waiting on $otherInterlocutor';

      case QuestionThreadsPageType.waitingForCurrUserForAllChatThreads: // TODO
        return 'Answer Waiting on You';

      case QuestionThreadsPageType.waitingOnOthersForAllChatThreads:
        return 'Waiting on Others';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MultipurposeQuestionThreadsPageCubit,
        MultipurposeQuestionThreadsPageState>(
      builder: (context, state) {
        if (state is MultipurposeQuestionThreadsPageLoaded) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                getAppBarText(state.allInterlocutors),
              ),
            ),
            body: MaxWidthView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (state.questionThreads.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Nothing here yet :)',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (state.questionThreads.isNotEmpty) ...[
                    Expanded(
                      child: AllQuestionThreads(
                        scrollController: _scrollController,
                        widget: widget,
                        questionThreadsPageType: widget.questionThreadsPageType,
                      ),
                    )
                  ]
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: LoadingDialog()),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state =
        BlocProvider.of<MultipurposeQuestionThreadsPageCubit>(context).state;
    if (_isBottom &&
        state is MultipurposeQuestionThreadsPageLoaded &&
        !state.hasReachedMax) {
      BlocProvider.of<MultipurposeQuestionThreadsPageCubit>(context)
          .loadQuestionThreads(widget.chatThreadId);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.75);
  }
}

class AllQuestionThreads extends StatelessWidget {
  const AllQuestionThreads({
    super.key,
    required ScrollController scrollController,
    required this.widget,
    required this.questionThreadsPageType,
  }) : _scrollController = scrollController;

  final ScrollController _scrollController;
  final MultipurposeQuestionThreadsPageView widget;
  final QuestionThreadsPageType questionThreadsPageType;

  bool needsOnSeeChatsFunction() {
    if (questionThreadsPageType ==
            QuestionThreadsPageType.waitingForCurrUserForAllChatThreads ||
        questionThreadsPageType ==
            QuestionThreadsPageType.waitingForCurrUserForSpecificChatThread) {
      return false;
    }
    return true;
  }

  List<Interlocutor> filterInterlocutors(
    List<Interlocutor> interlocutors,
    Interlocutor excludeInterlocutor,
  ) {
    return interlocutors
        .where((interlocutor) => interlocutor != excludeInterlocutor)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MultipurposeQuestionThreadsPageCubit>().state;

    if (state is MultipurposeQuestionThreadsPageLoaded) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => QuestionViewModel(
              questionsRepo: context.read<QuestionsRepo>(),
            ),
          ),
        ],
        child: ListView.builder(
          controller: _scrollController,
          itemCount: state.hasReachedMax
              ? state.questionThreads.length
              : state.questionThreads.length + 1,
          itemBuilder: (context, index) {
            if (index >= state.questionThreads.length) {
              return state.hasReachedMax
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'No more questions available',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                  : const BottomScreenLoader();
            } else {
              final questionThread = state.questionThreads[index];
              if (needsOnSeeChatsFunction()) {
                return QuestionCard(
                  key: UniqueKey(),
                  question: questionThread.question,
                  questionThreadUpdatedAt: questionThread.updatedAt,
                  questionThreadNumNewUnseenMessages:
                      questionThread.numNewUnseenMessages,
                  allConnectedInterlocutors:
                      getIt.get<GlobalState>().connectedInterlocutors,
                  hideAnswerButtons: true,
                  onSeeChats: () {
                    AutoRouter.of(context).push(
                      QuestionChatsRoute(
                        chatThreadId: questionThread.chatThread,
                        questionThreadId: questionThread.id,
                        question: questionThread.question,
                        interlocutors:
                            getIt.get<GlobalState>().connectedInterlocutors! +
                                [getIt.get<GlobalState>().currentInterlocutor!],
                        onSetToSeenSucceeded: () {
                          BlocProvider.of<MultipurposeQuestionThreadsPageCubit>(
                            context,
                          ).setQuestionThreadToFullySeen(
                            questionThread.id,
                          );
                        },
                      ),
                    );
                  },
                );
              } else {
                return QuestionCard(
                  key: UniqueKey(),
                  question: questionThread.question,
                  questionThreadUpdatedAt: questionThread.updatedAt,
                  questionThreadNumNewUnseenMessages:
                      questionThread.numNewUnseenMessages,
                  allConnectedInterlocutors:
                      getIt.get<GlobalState>().connectedInterlocutors,
                  // hideAnswerButtons: true,
                );
              }
            }
          },
        ),
      );
    } else {
      return Container(); // Return an empty container when the state is not MultipurposeQuestionThreadsPageLoaded
    }
  }
}
