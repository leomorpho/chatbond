import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/presentation/chats/chats/answer_question/cubit/answer_question_page_cubit.dart';
import 'package:chatbond/presentation/chats/chats/answer_question/interlocutor_selection_dialog.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/question_card.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

const textInputSaveDebounceTime = 500;

@RoutePage()
class AnswerQuestionPage extends StatelessWidget {
  const AnswerQuestionPage({
    super.key,
    required this.question,
    required this.allConnectedInterlocutors,
  });

  final Question question;
  final List<Interlocutor> allConnectedInterlocutors;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnswerQuestionPageCubit(
        chatThreadsRepo: context.read<ChatThreadsRepo>(),
        question: question,
        allConnectedInterlocutors: allConnectedInterlocutors,
      ),
      child: BlocBuilder<AnswerQuestionPageCubit, AnswerQuestionPageState>(
        builder: (context, state) {
          return AnswerQuestionWidget(
            question: question,
          );
        },
      ),
    );
  }
}

class AnswerQuestionWidget extends StatefulWidget {
  const AnswerQuestionWidget({
    super.key,
    required this.question,
  });

  final Question question;
  @override
  AnswerQuestionWidgetState createState() => AnswerQuestionWidgetState();
}

class AnswerQuestionWidgetState extends State<AnswerQuestionWidget> {
  late TextEditingController _controller;
  Interlocutor? _selectedInterlocutor;
  String savingStatus = '';
  Timer? _savingStatusTimer;
  Timer? _debounceTimer;
  String? _lastSavedText;
  bool get _isTextInputEnabled => _selectedInterlocutor != null;
  String? _publishedAt;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_handleTextChange);
  }

  // TODO: there is a bug when a WIP draft is first navigated to, it is
  // automatically saved again. Not a huge deal, but needs to be fixed eventually.
  void _handleTextChange() {
    if (_selectedInterlocutor != null &&
        _lastSavedText != _controller.text &&
        _controller.text != '') {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        const Duration(milliseconds: textInputSaveDebounceTime),
        _saveText,
      ); // _saveText will be called 500ms after the user stops typing
    }
  }

  /// TODO: looks like this would belong more to the cubit. It would also allow
  /// controlling the state of the Publish button from the cubit, as currently,
  /// text input state is saved in the UI, and after deleting a draft, the
  /// Publish button is still activated. Since clicking it results in no
  /// action, it's fine to leave for now, but fix as an annoying bug.
  Future<void> _saveText() async {
    // _lastSavedText = '';
    if (_selectedInterlocutor != null) {
      final state = context.read<AnswerQuestionPageCubit>().state;
      if (state is AnswerQuestionPageLoaded) {
        final currentDraft =
            state.interlocutorToDraftMap![_selectedInterlocutor!];

        DraftQuestionThread newDraft;
        if (currentDraft != null) {
          newDraft = currentDraft.copyWith(content: _controller.text);
        } else {
          // If there's no existing draft for the interlocutor, create a new one.
          newDraft = DraftQuestionThread(
            content: _controller.text,
            otherInterlocutor: _selectedInterlocutor!,
            question: widget.question.id,
          );
          // state.interlocutorToDraftMap![_selectedInterlocutor!] = newDraft;
        }

        final cursorPosition = _controller.selection.extentOffset;

        savingStatus = 'Saving...';
        _savingStatusTimer?.cancel(); // If there was a timer, cancel it
        if (mounted) {
          setState(() {
            savingStatus = savingStatus;
          });
        }

        await context.read<AnswerQuestionPageCubit>().upsertDraft(
              newDraft,
              cursorPosition,
            );

        // Restore the cursor position after the update
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );

        _savingStatusTimer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              savingStatus = 'Saved';
            });
          }
        });
        _lastSavedText = _controller.text;
      }
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChange)
      ..dispose();
    _savingStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _selectInterlocutor() async {
    final state = context.read<AnswerQuestionPageCubit>().state;
    List<Interlocutor>? interlocutors;
    Map<Interlocutor, DraftQuestionThread>? interlocutorToDraftMap;

    if (state is AnswerQuestionPageLoaded) {
      interlocutors = state.interlocutors;
      interlocutorToDraftMap = state.interlocutorToDraftMap;
    }

    final selectedInterlocutor = await showDialog<Interlocutor>(
      context: context,
      builder: (context) => InterlocutorSelectorDialog(
        interlocutors: interlocutors!,
        interlocutorToDraftMap: interlocutorToDraftMap,
        selectedInterlocutor: _selectedInterlocutor,
      ),
    );

    if (selectedInterlocutor != null) {
      // update the selected interlocutor
      if (mounted) {
        setState(() {
          _selectedInterlocutor = selectedInterlocutor;
          // Set the input text box to the draft content if it exists
          final draftThread = interlocutorToDraftMap?[selectedInterlocutor];
          final previousSelection = _controller.selection;
          _controller
            ..text = draftThread?.content ?? ''
            ..selection = previousSelection
            ..addListener(
              _handleTextChange,
            ); // Does that controller have to be in setState?
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Answer'),
      ),
      body: MaxWidthView(
        child: BlocConsumer<AnswerQuestionPageCubit, AnswerQuestionPageState>(
          listener: (context, state) {
            if (state is AnswerQuestionPageLoaded &&
                state.cursorPosition != null) {
              _selectedInterlocutor = state.selectedInterlocutor;
              _publishedAt = state
                  .interlocutorToDraftMap?[_selectedInterlocutor]?.publishedAt;
              _controller
                ..text = state.interlocutorToDraftMap?[_selectedInterlocutor]
                        ?.content ??
                    ''
                ..addListener(_handleTextChange)
                ..selection =
                    TextSelection.collapsed(offset: state.cursorPosition!);
              final newText = state
                      .interlocutorToDraftMap?[_selectedInterlocutor]
                      ?.content ??
                  '';
              _lastSavedText = newText;
            }
            if (state is AnswerQuestionPageFailed) {
              const snackBar = SnackBar(
                content: Text('Failed to save'),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: MultiProvider(
                      providers: [
                        ChangeNotifierProvider(
                          create: (context) => QuestionViewModel(
                            questionsRepo: context.read<QuestionsRepo>(),
                          ),
                        ),
                      ],
                      child: QuestionCard(
                        key: UniqueKey(),
                        question: context
                            .read<AnswerQuestionPageCubit>()
                            .state
                            .question,
                        hideAnswerButtons: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _selectInterlocutor,
                      child: Text(
                        _selectedInterlocutor != null
                            ? 'For: ${_selectedInterlocutor!.name}'
                            : 'Select Friend',
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      AnswerInputField(
                        controller: _controller,
                        enabled: _isTextInputEnabled,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Text(savingStatus),
                    ), // Display saving status
                  ),
                  AnswerActionButtons(
                    selectedInterlocutor: _selectedInterlocutor,
                    answerTextExists: _lastSavedText?.isNotEmpty ?? false,
                    answerPublishedAt: _publishedAt,
                    question: widget.question,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AnswerInputField extends StatelessWidget {
  AnswerInputField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ), // make corners round
          border: Border.all(
            color: Colors.grey,
          ), // draw border
        ),
        child: SingleChildScrollView(
          child: TextField(
            key: ValueKey(enabled),
            enabled: enabled,
            controller: controller,
            maxLines: null,
            decoration: InputDecoration(
              hintText: enabled
                  ? 'Enter your answer here...'
                  : 'Choose a friend first, then type your answer here',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(15),
            ),
          ),
        ),
      ),
    );
  }
}

class CogsButton extends StatelessWidget {
  const CogsButton({super.key, required this.onDeleteDraft});
  final VoidCallback? onDeleteDraft;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings), // This is the cog icon
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      Icons.delete,
                      color: onDeleteDraft != null
                          ? Theme.of(context)
                              .iconTheme
                              .color // Color when active
                          : Theme.of(context)
                              .disabledColor, // Color when disabled
                    ),
                    title: Text(
                      'Delete current draft',
                      style: TextStyle(
                        color: onDeleteDraft != null
                            ? Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color // Color when active
                            : Theme.of(context)
                                .disabledColor, // Color when disabled
                      ),
                    ),
                    onTap: onDeleteDraft != null
                        ? () {
                            onDeleteDraft!();
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.cancel),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AnswerActionButtons extends StatelessWidget {
  const AnswerActionButtons({
    super.key,
    required this.selectedInterlocutor,
    required this.answerTextExists,
    required this.question,
    this.answerPublishedAt,
  });
  final Interlocutor? selectedInterlocutor;
  final bool answerTextExists;
  final Question question;

  /// If already published, we cannot re-publish. This is a safeguard as the
  /// user should not be able to select the relevant interlocutor in
  /// the first place.
  final String? answerPublishedAt;

  @override
  Widget build(BuildContext context) {
    final buttonIsActive = selectedInterlocutor != null &&
        answerTextExists &&
        answerPublishedAt == null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
          child: SettingsButton(selectedInterlocutor: selectedInterlocutor),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 8, 8),
          child: PublishButton(
            buttonIsActive: buttonIsActive,
            selectedInterlocutor: selectedInterlocutor,
            question: question,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
    required this.selectedInterlocutor,
  });

  final Interlocutor? selectedInterlocutor;

  @override
  Widget build(BuildContext context) {
    final currentState =
        BlocProvider.of<AnswerQuestionPageCubit>(context).state;

    if (currentState is AnswerQuestionPageLoaded) {
      // Do your logic here
      return CogsButton(
        onDeleteDraft: selectedInterlocutor != null &&
                currentState.interlocutorToDraftMap != null &&
                currentState.interlocutorToDraftMap![selectedInterlocutor!] !=
                    null
            ? () async {
                await BlocProvider.of<AnswerQuestionPageCubit>(context)
                    .deleteDraft(
                  currentState.interlocutorToDraftMap![selectedInterlocutor!]!,
                );
              }
            : null,
      );
    } else {
      // Handle other states like AnswerQuestionPageLoading, AnswerQuestionPageError, etc.
      return const LoadingDialog();
    }
  }
}

class PublishButton extends StatelessWidget {
  const PublishButton({
    super.key,
    required this.buttonIsActive,
    required this.selectedInterlocutor,
    required this.question,
  });

  final bool buttonIsActive;
  final Interlocutor? selectedInterlocutor;
  final Question question;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: !buttonIsActive
          ? null
          : () async {
              final state = BlocProvider.of<AnswerQuestionPageCubit>(context)
                  .state as AnswerQuestionPageLoaded;

              final draft =
                  state.interlocutorToDraftMap![selectedInterlocutor!];

              if (draft != null) {
                /// TODO: it's difficult to do something more disgusting
                /// than the following. While an achievement, fix someday.
                final publishedDraft =
                    await BlocProvider.of<AnswerQuestionPageCubit>(
                  context,
                ).publishDraft(draft.id!);
                // TODO: if everyone answered the question, redirect to the convo
                if (publishedDraft != null) {
                  final questionThread =
                      await BlocProvider.of<AnswerQuestionPageCubit>(
                    context,
                  ).chatThreadsRepo.getQuestionThread(
                            publishedDraft.questionThread!,
                          );

                  if (questionThread.allInterlocutorsAnswered) {
// If everyone answered the question, redirect to the associated chats
                    await context.navigateTo(
                      PeopleRouter(
                        children: [
                          QuestionChatsRoute(
                            chatThreadId: publishedDraft.chatThread!,
                            questionThreadId: publishedDraft.questionThread!,
                            question: question,
                            interlocutors: [
                              selectedInterlocutor!,
                              getIt.get<GlobalState>().currentInterlocutor!,
                            ],
                            onSetToSeenSucceeded: () {},
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  const snackBar = SnackBar(
                    content: Text('Published answer'),
                  ); // TODO: internationalize
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }

                await context.router.pop();
              }
            },
      child: const Text('Publish'),
    );
  }
}
