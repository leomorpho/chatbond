import 'package:auto_route/auto_route.dart';
import 'package:chatbond/bootstrap.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/constants.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/presentation/chats/chats/question_threads_page/main/question_threads_page_cubit/question_threads_page_cubit.dart';
import 'package:chatbond/presentation/shared_widgets/bottom_loader.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/menu_item.dart';
import 'package:chatbond/presentation/shared_widgets/profile_pic.dart';
import 'package:chatbond/presentation/shared_widgets/question_card.dart';
import 'package:chatbond/utils.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:provider/provider.dart';

enum QuestionThreadsPageType {
  waitingForCurrUserForSpecificChatThread,
  waitingOnOthersForSpecificChatThread,
  waitingForCurrUserForAllChatThreads,
  waitingOnOthersForAllChatThreads,
}

// TODO: move to somewhere more appropriate
enum QuestionsPageType {
  draftsForSpecificChatThread,
  draftsForAllChatThreads,
  favorites
}

@RoutePage()
class QuestionThreadsPage extends AutoRouter {
  const QuestionThreadsPage({
    super.key,
    @PathParam('chatThread') required this.chatThreadId,
    required this.currentInterlocutor,
    required this.otherInterlocutors,
  });

  final String chatThreadId;
  final Interlocutor currentInterlocutor;
  final List<Interlocutor> otherInterlocutors;

  @override
  State<QuestionThreadsPage> createState() => _QuestionThreadsPageState();
}

class _QuestionThreadsPageState extends State<QuestionThreadsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestionThreadsPageCubit(
        chatThreadsRepo: context.read<ChatThreadsRepo>(),
        questionsRepo: context.read<QuestionsRepo>(),
        numTotalNotificationsStream:
            context.read<ChatProvider>().numTotalNotificationsController.stream,
        otherInterlocutors: widget.otherInterlocutors,
      )..loadQuestionThreads(widget.chatThreadId),
      child: QuestionThreadsPageView(
        chatThreadId: widget.chatThreadId,
        otherInterlocutors: widget.otherInterlocutors,
        currentInterlocutor: widget.currentInterlocutor,
      ),
    );
  }
}

class QuestionThreadsPageView extends StatefulWidget {
  const QuestionThreadsPageView({
    super.key,
    required this.chatThreadId,
    required this.otherInterlocutors,
    required this.currentInterlocutor,
  });

  final String chatThreadId;
  final List<Interlocutor> otherInterlocutors;
  final Interlocutor currentInterlocutor;

  @override
  QuestionThreadsPageViewState createState() => QuestionThreadsPageViewState();
}

class QuestionThreadsPageViewState extends State<QuestionThreadsPageView>
    with WidgetsBindingObserver {
  late VisibilityChangeNotifier _visibilityChangeNotifier;

  @override
  void initState() {
    super.initState();
    _scrollController
      ..addListener(_onScroll)
      ..addListener(handleScroll);

    _visibilityChangeNotifier = VisibilityChangeNotifier(
      thresholdInSeconds: visibilityChangeNotifierTimespan,
      onThresholdExceeded: () async {
        // Replace this line with the code you want to execute when threshold is exceeded
        logDebug('access token invalid, attempting to log in automatically...');
        await context
            .read<QuestionThreadsPageCubit>()
            .loadQuestionThreads(widget.chatThreadId);
      },
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _visibilityChangeNotifier.dispose();

    _scrollController
      ..dispose()
      ..removeListener(handleScroll);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void handleScroll() {
    setExpandState(_scrollController.position.userScrollDirection);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // when the app returns from the background
      BlocProvider.of<QuestionThreadsPageCubit>(context)
          .loadQuestionThreads(widget.chatThreadId);
    }
  }

  final _scrollController = ScrollController();
  bool isExpanded = true;

  void setExpandState(ScrollDirection direction) {
    if (direction == ScrollDirection.reverse) {
      // Scroll down
      if (isExpanded) {
        if (mounted) {
          setState(() {
            isExpanded = false;
          });
        }
      }
    } else if (direction == ScrollDirection.forward &&
        _scrollController.offset <= 0) {
      // Scroll up and at the top
      if (!isExpanded) {
        if (mounted) {
          setState(() {
            isExpanded = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInterlocutorNames =
        createNameStrFromInterlocutors(widget.otherInterlocutors);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: supports only 1 other interlocutor
            ProfilePicture(
              username: widget.otherInterlocutors[0].username,
              email: widget.otherInterlocutors[0].email,
            ),
            const SizedBox(
              width: 16,
            ),
            Text(filteredInterlocutorNames),
          ],
        ),
      ),
      body: MaxWidthView(
        child: BlocBuilder<QuestionThreadsPageCubit, QuestionThreadsPageState>(
          builder: (context, state) {
            if (state is QuestionThreadsPageLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExpansionPanelList(
                    expansionCallback: (int index, bool isExpanded) {
                      if (mounted) {
                        setState(() {
                          // toggles the expanded state
                          this.isExpanded = !this.isExpanded;
                        });
                      }
                    },
                    children: [
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return const ListTile(
                            title: Text('Answers Menu'),
                          );
                        },
                        body: Column(
                          children: <Widget>[
                            MenuItem(
                              iconData: Icons.chat,
                              titleWidget: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                        state.waitingOnYouQuestionCount
                                            .toString(),
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
                                    chatThreadId: widget.chatThreadId,
                                    currentInterlocutor:
                                        widget.currentInterlocutor,
                                    questionThreadsPageType: QuestionThreadsPageType
                                        .waitingForCurrUserForSpecificChatThread,
                                    allInterlocutors: widget.otherInterlocutors,
                                  ),
                                );
                              },
                            ),
                            MenuItem(
                              iconData: Icons.hourglass_top,
                              title:
                                  '${state.waitingOnOthersQuestionCount} Pending '
                                  'for $filteredInterlocutorNames',
                              onTap: () {
                                context.router.push(
                                  MultipurposeQuestionThreadsRoute(
                                    chatThreadId: widget.chatThreadId,
                                    currentInterlocutor:
                                        widget.currentInterlocutor,
                                    questionThreadsPageType:
                                        QuestionThreadsPageType
                                            .waitingOnOthersForSpecificChatThread,
                                    allInterlocutors: widget.otherInterlocutors,
                                  ),
                                );
                              },
                            ),
                            MenuItem(
                              iconData: Icons.edit_document,
                              title:
                                  '${state.draftsCount} Drafts', // TODO: show number of questions
                              onTap: () {
                                context.router.push(
                                  MultipurposeQuestionsRoute(
                                    chatThreadId: widget.chatThreadId,
                                    currentInterlocutor:
                                        widget.currentInterlocutor,
                                    otherInterlocutors:
                                        widget.otherInterlocutors,
                                    questionsPageType: QuestionsPageType
                                        .draftsForSpecificChatThread,
                                    /**
                                     *  TODO: All interlocutors within the chat thread:
                                     * rename param to allRelevantInterlocutors
                                     * or something more meaningfull. Note that this
                                     * page is used for more than 1 purpose...hence
                                     * the name...
                                     */
                                  ),
                                );
                              },
                            ),
                            // TODO: for later, not for MVP
                            // MenuItem(
                            //   iconData: Icons.question_mark,
                            //   title: 'Ask New Question',
                            //   onTap: () {}, // TODO
                            // ),
                          ],
                        ),
                        isExpanded: isExpanded,
                      ),
                    ],
                  ),
                  if (state.questionThreads.isEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Nothing here yet. Go answer some questions for this person to see question threads here',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (state.questionThreads.isNotEmpty) ...[
                    Expanded(
                      child: AllQuestionThreadsWidget(
                        scrollController: _scrollController,
                        widget: widget,
                      ),
                    )
                  ],
                ],
              );
            } else {
              return const LoadingDialog();
            }
          },
        ),
      ),
    );
  }

  void _onScroll() {
    final state = BlocProvider.of<QuestionThreadsPageCubit>(context).state;
    if (_isBottom &&
        state is QuestionThreadsPageLoaded &&
        !state.hasReachedMax) {
      BlocProvider.of<QuestionThreadsPageCubit>(context)
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

class AllQuestionThreadsWidget extends StatelessWidget {
  const AllQuestionThreadsWidget({
    super.key,
    required ScrollController scrollController,
    required this.widget,
  }) : _scrollController = scrollController;

  final ScrollController _scrollController;
  final QuestionThreadsPageView widget;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuestionThreadsPageCubit>().state;

    if (state is QuestionThreadsPageLoaded) {
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
              return QuestionCard(
                question: questionThread.question,
                questionThreadUpdatedAt: questionThread.updatedAt,
                questionThreadNumNewUnseenMessages:
                    questionThread.numNewUnseenMessages,
                hideAnswerButtons: true,
                onSeeChats: () {
                  context.navigateTo(
                    QuestionChatsRoute(
                      chatThreadId: questionThread.chatThread,
                      questionThreadId: questionThread.id,
                      question: questionThread.question,
                      interlocutors: widget.otherInterlocutors +
                          [widget.currentInterlocutor],
                      onSetToSeenSucceeded: () {
                        BlocProvider.of<QuestionThreadsPageCubit>(context)
                            .setQuestionThreadToFullySeen(
                          questionThread.id,
                        );
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      );
    } else {
      return Container(); // Return an empty container when the state is not QuestionThreadsPageLoaded
    }
  }
}
