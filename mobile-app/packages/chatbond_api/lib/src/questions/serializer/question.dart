import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';

enum QuestionStatusEnum {
  Pending, // P
  Approved, // A
  Rejected, // R
  Private, // V
}

enum VoteStatus { upvoted, downvoted, neutral }

extension ParseVoteStatusToString on VoteStatus {
  String get value {
    switch (this) {
      case VoteStatus.upvoted:
        return 'L';
      case VoteStatus.downvoted:
        return 'D';
      case VoteStatus.neutral:
        return 'N';
    }
  }
}

enum FavoriteState { favorite, unfavorite }

extension ParseFavoriteStateToString on FavoriteState {
  String get value {
    switch (this) {
      case FavoriteState.favorite:
        return 'favorite';
      case FavoriteState.unfavorite:
        return 'unfavorite';
    }
  }
}

class Question extends Equatable {
  Question({
    required this.id,
    required this.cumulativeVotingScore,
    required this.timesVoted,
    required this.timesAnswered,
    required this.createdAt,
    required this.updatedAt,
    required this.content,
    required this.answeredByFriends,
    this.isActive,
    this.author,
    this.isPrivate,
    this.status,
    this.isFavorited = false,
    this.currInterlocutorVotingStatus = VoteStatus.neutral,
    this.unpublishedDrafts,
    this.publishedDrafts,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      cumulativeVotingScore: json['cumulative_voting_score'] as int,
      timesVoted: json['times_voted'] as int,
      timesAnswered: json['times_answered'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      content: json['content'] as String,
      isActive: json['is_active'] as bool?,
      author: json['author'] is Map<String, dynamic>
          ? Interlocutor.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      isPrivate: json['is_private'] as bool?,
      status: json['status'] != null
          ? statusFromJson(json['status'] as String)
          : null,
      isFavorited: json['is_favorite'] as bool?,
      currInterlocutorVotingStatus: json['user_rating'] != null
          ? ratingFromJson(json['user_rating'] as String)
          : VoteStatus.neutral,
      answeredByFriends: (json['answered_by_friends'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      unpublishedDrafts: (json['unpublished_drafts'] as List?)
          ?.map((i) => DraftQuestionThread.fromJson(i as Map<String, dynamic>))
          .toList(),
      publishedDrafts: (json['published_drafts'] as List?)
          ?.map((i) => DraftQuestionThread.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
  static QuestionStatusEnum statusFromJson(String status) {
    switch (status) {
      case 'A':
        return QuestionStatusEnum.Approved;
      case 'R':
        return QuestionStatusEnum.Rejected;
      case 'V':
        return QuestionStatusEnum.Private;
      default:
        return QuestionStatusEnum.Pending;
    }
  }

  String? statusToJson(QuestionStatusEnum? status) {
    switch (status) {
      case QuestionStatusEnum.Approved:
        return 'A';
      case QuestionStatusEnum.Rejected:
        return 'R';
      case QuestionStatusEnum.Private:
        return 'V';
      default:
        return 'P';
    }
  }

  static VoteStatus ratingFromJson(String rating) {
    switch (rating) {
      case 'L':
        return VoteStatus.upvoted;
      case 'D':
        return VoteStatus.downvoted;
      default:
        return VoteStatus.neutral; // or define a default state
    }
  }

  String? ratingToJson(VoteStatus? rating) {
    switch (rating) {
      case VoteStatus.upvoted:
        return 'L';
      case VoteStatus.downvoted:
        return 'D';
      default:
        return ''; // or define a default state
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cumulative_voting_score': cumulativeVotingScore,
      'times_voted': timesVoted,
      'times_answered': timesAnswered,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'content': content,
      'is_active': isActive,
      'author': author?.toJson(),
      'is_private': isPrivate,
      'status': statusToJson(status),
      'user_rating': ratingToJson(currInterlocutorVotingStatus),
      // TODO: may need to add missing fields if wanting to cache with hydration
    };
  }

  final String id;
  int cumulativeVotingScore;
  final int timesVoted;
  final int timesAnswered;
  final String createdAt;
  final String updatedAt;
  final String content;
  final bool? isActive;
  final Interlocutor? author;
  final bool? isPrivate;
  final QuestionStatusEnum? status;
  bool? isFavorited;
  VoteStatus currInterlocutorVotingStatus;
  final List<String> answeredByFriends;
  final List<DraftQuestionThread>? unpublishedDrafts;
  final List<DraftQuestionThread>? publishedDrafts;

  @override
  List<Object> get props => [
        id,
        cumulativeVotingScore,
        timesVoted,
        timesAnswered,
        createdAt,
        updatedAt,
        content,
        isActive ?? false,
        isPrivate ?? true,
        status ?? QuestionStatusEnum.Private,
        currInterlocutorVotingStatus,
        isFavorited ?? false,
        unpublishedDrafts ?? 0,
        publishedDrafts ?? 0
      ];

  Question copyWith({
    String? id,
    int? cumulativeVotingScore,
    int? timesVoted,
    int? timesAnswered,
    String? createdAt,
    String? updatedAt,
    String? content,
    bool? isActive,
    Interlocutor? author,
    bool? isPrivate,
    QuestionStatusEnum? status,
    bool? isFavorited,
    VoteStatus? currInterlocutorVotingStatus,
    List<String>? answeredByFriends,
    List<DraftQuestionThread>? unpublishedDrafts,
    List<DraftQuestionThread>? publishedDrafts,
  }) {
    return Question(
      id: id ?? this.id,
      cumulativeVotingScore:
          cumulativeVotingScore ?? this.cumulativeVotingScore,
      timesVoted: timesVoted ?? this.timesVoted,
      timesAnswered: timesAnswered ?? this.timesAnswered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      content: content ?? this.content,
      isActive: isActive ?? this.isActive,
      author: author ?? this.author,
      isPrivate: isPrivate ?? this.isPrivate,
      status: status ?? this.status,
      isFavorited: isFavorited ?? this.isFavorited,
      currInterlocutorVotingStatus:
          currInterlocutorVotingStatus ?? this.currInterlocutorVotingStatus,
      answeredByFriends: answeredByFriends ?? this.answeredByFriends,
      unpublishedDrafts: unpublishedDrafts ?? this.unpublishedDrafts,
      publishedDrafts: publishedDrafts ?? this.publishedDrafts,
    );
  }
}

extension QuestionListExtension on List<Question> {
  List<Question> updateVotingScore(
    String questionId,
    VoteStatus oldVotingStatus,
    VoteStatus newVotingStatus,
  ) {
    return map((question) {
      if (question.id == questionId) {
        late int increment;
        if (oldVotingStatus == VoteStatus.downvoted &&
            newVotingStatus == VoteStatus.neutral) {
          increment = 1;
        } else if (oldVotingStatus == VoteStatus.upvoted &&
            newVotingStatus == VoteStatus.neutral) {
          increment = -1;
        } else if (newVotingStatus == VoteStatus.upvoted) {
          increment = 1;
        } else {
          increment = -1;
        }

        return question.copyWith(
          cumulativeVotingScore: question.cumulativeVotingScore + increment,
          currInterlocutorVotingStatus: newVotingStatus,
        );
      } else {
        return question;
      }
    }).toList();
  }

  List<Question> updateFavoritedStatus(
    String questionId,
    FavoriteState newFavoriteState,
  ) {
    return map((question) {
      if (question.id == questionId) {
        return question.copyWith(
          isFavorited: newFavoriteState == FavoriteState.favorite,
        );
      } else {
        return question;
      }
    }).toList();
  }
}
