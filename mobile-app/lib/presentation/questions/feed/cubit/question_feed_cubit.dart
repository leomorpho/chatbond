import 'package:bloc/bloc.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';

part 'question_feed_state.dart';

class QuestionFeedCubit extends Cubit<QuestionFeedState> {
  QuestionFeedCubit() : super(QuestionFeedInitial()) {
    fetchQuestions();
  }

  void fetchQuestions() {
    // Start fetching questions
    emit(QuestionFeedLoadInProgress());

    try {
      // In real application, you will call api to fetch questions
      final fetchedQuestions = _fakeQuestions();

      // Emit success state with fetched questions
      emit(QuestionFeedLoadSuccess(questions: fetchedQuestions));
    } catch (error) {
      // Emit failure state in case of any exception
      emit(QuestionFeedLoadFailure());
    }
  }

  void favoriteQuestion(String id) {
    if (state is QuestionFeedLoadSuccess) {
      final currentState = state as QuestionFeedLoadSuccess;
      final newQuestions = currentState.questions.map((q) {
        if (q.id == id) {
          return q.copyWith();
        }
        return q;
      }).toList();
      emit(QuestionFeedLoadSuccess(questions: newQuestions));
    }
  }

  void upvoteQuestion(String id) {
    if (state is QuestionFeedLoadSuccess) {
      final currentState = state as QuestionFeedLoadSuccess;
      final newQuestions = currentState.questions.map((q) {
        if (q.id == id) {
          return q.copyWith(cumulativeVotingScore: q.cumulativeVotingScore + 1);
        }
        return q;
      }).toList();
      emit(QuestionFeedLoadSuccess(questions: newQuestions));
    }
  }

  void downvoteQuestion(String id) {
    if (state is QuestionFeedLoadSuccess) {
      final currentState = state as QuestionFeedLoadSuccess;
      final newQuestions = currentState.questions.map((q) {
        if (q.id == id) {
          return q.copyWith(cumulativeVotingScore: q.cumulativeVotingScore - 1);
        }
        return q;
      }).toList();
      emit(QuestionFeedLoadSuccess(questions: newQuestions));
    }
  }

  // Dummy method. In real application, you would use a router or navigator.
  void goToAnswerPage(String id) {
    print('Redirecting to answer page for question $id');
  }
}

// A dummy function to generate some fake questions
List<Question> _fakeQuestions() {
  return List<Question>.generate(
    10,
    (index) => Question(
        id: 'id_$index',
        cumulativeVotingScore: index,
        timesVoted: index,
        timesAnswered: index,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
        content: 'This is a fake question number $index',
        isActive: true,
        isPrivate: false,
        status: QuestionStatusEnum.Approved,
        answeredByFriends: const []),
  );
}
