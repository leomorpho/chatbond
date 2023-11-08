import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatbond/presentation/questions/feed/cubit/question_feed_cubit.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/question_card.dart';

class QuestionsFeedWidget extends StatelessWidget {
  const QuestionsFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestionFeedCubit(),
      child: BlocBuilder<QuestionFeedCubit, QuestionFeedState>(
        builder: (context, state) {
          if (state is QuestionFeedLoadSuccess) {
            final questions = state.questions;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return QuestionCard(question: question);
              },
            );
          }
          // For the other states, return an appropriate widget.
          else if (state is QuestionFeedLoadInProgress) {
            return const LoadingDialog();
          } else if (state is QuestionFeedLoadFailure) {
            return const Center(child: Text('Failed to load questions'));
          } else {
            // TODO: this should never happen...
            return const Center(child: Text('Unexpected state'));
          }
        },
      ),
    );
  }
}
