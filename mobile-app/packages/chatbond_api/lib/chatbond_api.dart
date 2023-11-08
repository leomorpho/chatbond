library chatbond_api;

import 'package:loggy/loggy.dart';

export 'src/chatbond_api.dart';
export 'src/chats/serializer/chat_thread.dart';
export 'src/chats/serializer/chat_thread_stats.dart';
export 'src/chats/serializer/draft_question_thread.dart';
export 'src/chats/serializer/interlocutor.dart';
export 'src/chats/serializer/paginated_draft_question_threads.dart';
export 'src/chats/serializer/paginated_question_threads.dart';
export 'src/chats/serializer/question_chat.dart';
export 'src/chats/serializer/question_chat_interaction_event.dart';
export 'src/chats/serializer/question_thread.dart';
export 'src/invitations/serializer/invitation.dart';
export 'src/questions/questions.dart';
export 'src/questions/serializer/paginated_questions.dart';
export 'src/questions/serializer/question.dart';
export 'src/questions/serializer/question_feed_with_metadata.dart';
export 'src/realtime/serializer/realtime_event.dart';
export 'src/users/serializer/user.dart';

void main() {
  Loggy.initLoggy(
    logPrinter: const PrettyPrinter(),
    filters: [],
    // TODO: set up a production logger like below
    // logPrinter: kReleaseMode ? CrashlyticsPrinter() : PrettyPrinter(),
  );
}
