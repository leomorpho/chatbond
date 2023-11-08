import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/presentation/chats/chats/question_threads_page/main/question_threads_page.dart';
import 'package:chatbond/presentation/chats/chats/question_threads_page/multipurpose_questions_page/cubit/multipurpose_questions_page_cubit.dart';
import 'package:chatbond/presentation/shared_widgets/bottom_loader.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/question_card.dart';
import 'package:chatbond/utils.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:provider/provider.dart';

@RoutePage()
class MultipurposeQuestionsPage extends StatelessWidget {
  const MultipurposeQuestionsPage({
    super.key,
    @PathParam('chatThread') this.chatThreadId,
    required this.questionsPageType,
    required this.currentInterlocutor,
    required this.otherInterlocutors,
  });

  final QuestionsPageType questionsPageType;
  final Interlocutor currentInterlocutor; // TODO: make required
  final List<Interlocutor> otherInterlocutors;
  final String? chatThreadId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MultipurposeQuestionsPageCubit(
        questionsRepo: context.read<QuestionsRepo>(),
        chatsRepo: context.read<ChatThreadsRepo>(),
        questionsPageType: questionsPageType,
      )..loadQuestions(chatThreadId),
      child: MultipurposeQuestionsPageView(
        questionsPageType: questionsPageType,
        chatThreadId: chatThreadId,
        otherInterlocutors: otherInterlocutors,
        currentInterlocutor: currentInterlocutor,
      ),
    );
  }
}

class MultipurposeQuestionsPageView extends StatefulWidget {
  const MultipurposeQuestionsPageView({
    super.key,
    required this.questionsPageType,
    required this.currentInterlocutor,
    required this.otherInterlocutors,
    this.chatThreadId,
  });
  final QuestionsPageType questionsPageType;
  final String? chatThreadId;

  // TODO: currentInterlocutor is nullable but we access it with ! later, we need to
  // query it before if it's missing.
  final Interlocutor currentInterlocutor;
  final List<Interlocutor> otherInterlocutors;

  @override
  MultipurposeQuestionsPageViewState createState() =>
      MultipurposeQuestionsPageViewState();
}

class MultipurposeQuestionsPageViewState
    extends State<MultipurposeQuestionsPageView> {
  final _scrollController = ScrollController();
  StreamSubscription<MultipurposeQuestionsPageState>? _blocSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If there's an existing subscription, cancel it
    _blocSubscription?.cancel();

    // Then create a new one
    _blocSubscription =
        BlocProvider.of<MultipurposeQuestionsPageCubit>(context).stream.listen(
      (state) {
        // Just by listening to the bloc state in didChangeDependencies,
        // we ensure that the widget rebuilds when it comes back into view
        // and a new state has been emitted.
      },
    );
  }

  String getAppBarText(List<Interlocutor> otherInterlocutors) {
    switch (widget.questionsPageType) {
      case QuestionsPageType.draftsForSpecificChatThread:
        return 'Drafts for ${createNameStrFromInterlocutors(otherInterlocutors)}';
      case QuestionsPageType.draftsForAllChatThreads:
        return 'All Drafts';

      case QuestionsPageType.favorites:
        return 'Favorites';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MultipurposeQuestionsPageCubit,
        MultipurposeQuestionsPageState>(
      builder: (context, state) {
        if (state is MultipurposeQuestionsPageLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const LoadingDialog(),
          );
        } else if (state is MultipurposeQuestionsPageLoaded) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                getAppBarText(widget.otherInterlocutors),
              ),
            ),
            body: MaxWidthView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (state.questions.isEmpty) ...[
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
                  if (state.questions.isNotEmpty) ...[
                    Expanded(
                      child: MultiProvider(
                        providers: [
                          ChangeNotifierProvider(
                            create: (context) => QuestionViewModel(
                              questionsRepo: context.read<QuestionsRepo>(),
                            ),
                          ),
                        ],
                        child: ListView.builder(
                          // <- you missed this return
                          controller: _scrollController,
                          itemCount: state.hasReachedMax
                              ? state.questions.length + 1
                              : state.questions.length + 1,
                          itemBuilder: (context, index) {
                            if (index >= state.questions.length) {
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
                              return QuestionCard(
                                  key: GlobalKey(),
                                  question: state.questions[index],
                                  allConnectedInterlocutors:
                                      filterInterlocutors(
                                    interlocutorsToFilter:
                                        widget.otherInterlocutors,
                                    interlocutorToExclude:
                                        widget.currentInterlocutor,
                                  ));
                            }
                          },
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink(); // For the initial state
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _blocSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final state =
        BlocProvider.of<MultipurposeQuestionsPageCubit>(context).state;
    if (_isBottom &&
        state is MultipurposeQuestionsPageLoaded &&
        !state.hasReachedMax) {
      BlocProvider.of<MultipurposeQuestionsPageCubit>(context)
          .loadQuestions(widget.chatThreadId);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.75);
  }
}
