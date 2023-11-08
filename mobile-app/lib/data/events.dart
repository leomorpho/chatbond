import 'package:chatbond_api/chatbond_api.dart';

class QuestionChatsSeenEvent {
  QuestionChatsSeenEvent({
    required this.questionThreadId,
  });

  final String questionThreadId;
}

class DraftCreatedEvent {
  DraftCreatedEvent({
    required this.draft,
  });

  final DraftQuestionThread draft;
}

class DraftPublishedEvent {
  DraftPublishedEvent({
    required this.draft,
  });

  final DraftQuestionThread draft;
}

class DraftUpsertEvent {
  DraftUpsertEvent({
    required this.draft,
  });

  final DraftQuestionThread draft;
}

class DraftDeleteEvent {
  DraftDeleteEvent({
    required this.draft,
  });

  final DraftQuestionThread draft;
}

class QuestionFavoritingEvent {
  QuestionFavoritingEvent({
    required this.questionId,
    this.favoritedStatus,
  });

  final String questionId;
  final FavoriteState? favoritedStatus;
}

class QuestionVotingEvent {
  QuestionVotingEvent({
    required this.questionId,
    this.oldVotingStatus,
    this.newVotingStatus,
    this.favoritedStatus,
  });

  final String questionId;
  final VoteStatus? oldVotingStatus;
  final VoteStatus? newVotingStatus;
  final FavoriteState? favoritedStatus;
}

/// When a friend accepts an invitation for the current interlocutor, this event
/// is published to the listened socket.
/// TODO: refresh objects on app back to foreground
class InvitationAcceptedEvent {
  InvitationAcceptedEvent({required this.chatThread});

  final ChatThread chatThread;
}

class InvitationCreatedEvent {
  InvitationCreatedEvent({required this.invitation});

  final Invitation invitation;
}

/// When a friend publishes a draft to the current interlocutor, this event
/// is published to the listened socket.
class FriendPublishedDraftEvent {
  FriendPublishedDraftEvent({required this.questionThread});

  final QuestionThread questionThread;
}

/// When a friend publishes a chat to the current interlocutor, this event
/// is published to the listened socket.
class FriendPublishedQuestionChatEvent {
  FriendPublishedQuestionChatEvent({required this.questionChat});

  final QuestionChat questionChat;
}
