import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/presentation/shared_widgets/profile_pic.dart';
import 'package:chatbond/presentation/shared_widgets/updated_at_text_widget.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loggy/loggy.dart';
import 'package:provider/provider.dart';

enum PublishingState {
  None,
  Draft,
  Published,
}

enum UpdateResult {
  Updated,
  AlreadyUpdated,
  FailedToUpdate,
}

enum VoteAction {
  upvote,
  downvote,
}

class QuestionViewModel with ChangeNotifier {
  // TODO: this could be improved, re-architecture
  QuestionViewModel({required this.questionsRepo});
  final QuestionsRepo questionsRepo;

  Future<UpdateResult> vote(
    String questionId,
    VoteStatus oldVotingStatus,
    VoteStatus newVotingStatus,
  ) async {
    try {
      final success = await questionsRepo.rateQuestion(
        questionId,
        oldVotingStatus,
        newVotingStatus,
      );
      if (success) {
        return UpdateResult.Updated;
      } else {
        return UpdateResult.AlreadyUpdated;
      }
    } catch (e) {
      logError(
        'Error while voting on question $questionId: $e',
      );
      return UpdateResult.FailedToUpdate;
    }
  }

  Future<UpdateResult> favoriteQuestion(
    String questionId,
    FavoriteState favouriteAction,
  ) async {
    try {
      final success = await questionsRepo.favoriteQuestion(
        questionId,
        favouriteAction,
      );
      if (success) {
        return UpdateResult.Updated;
      } else {
        return UpdateResult.AlreadyUpdated;
      }
    } catch (e) {
      logError(
        'Error while ${favouriteAction == FavoriteState.favorite ? 'favoriting' : 'unfavoriting'} question $questionId: $e',
      );
      return UpdateResult.FailedToUpdate;
    }
  }
}

class QuestionCard extends StatefulWidget {
  const QuestionCard({
    super.key,
    required this.question,
    this.allConnectedInterlocutors,
    this.questionThreadUpdatedAt,
    this.questionThreadNumNewUnseenMessages,
    this.onSeeChats,
    this.hideAnswerButtons = false,
  });

  /// The question that this Card presents.
  final Question question;

  /// The interlocutors connected to the currently logged in interlocutor.
  final List<Interlocutor>? allConnectedInterlocutors;

  final String? questionThreadUpdatedAt;
  final int? questionThreadNumNewUnseenMessages;
  final VoidCallback? onSeeChats;
  final bool hideAnswerButtons;

  @override
  QuestionCardState createState() => QuestionCardState();
}

class QuestionCardState extends State<QuestionCard> {
  late int cumulativeVotingScore;
  late VoteStatus voteStatus;
  late bool isFavorited;

  bool get isQuestionAnsweredForAll {
    // Use a default value of 0 if publishedDrafts or allConnectedInterlocutors is null.
    final publishedDraftsLength = widget.question.publishedDrafts?.length ?? 0;
    final interlocutorsLength = widget.allConnectedInterlocutors?.length ?? 0;

    return publishedDraftsLength >= interlocutorsLength &&
        publishedDraftsLength != 0 &&
        interlocutorsLength != 0;
  }

  List<String> getFriendNamesFromUUIDs(List<String> uuids) {
    return widget.allConnectedInterlocutors
            ?.where((interlocutor) => uuids.contains(interlocutor.id))
            .map((interlocutor) => interlocutor.name)
            .toList() ??
        [];
  }

  String get buttonText {
    if (isQuestionAnsweredForAll) {
      return 'Answered for all';
    } else if (widget.question.unpublishedDrafts == null ||
        (widget.question.unpublishedDrafts != null &&
            widget.question.unpublishedDrafts!.isEmpty)) {
      return 'Answer';
    } else {
      return 'Continue draft';
    }
  }

  @override
  void initState() {
    super.initState();
    cumulativeVotingScore = widget.question.cumulativeVotingScore;
    voteStatus = widget.question.currInterlocutorVotingStatus;
    isFavorited = widget.question.isFavorited ?? false;
  }

  Future<void> onVote(VoteAction voteAction) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    late VoteStatus newStatus;

    if (voteAction == VoteAction.upvote) {
      if (widget.question.currInterlocutorVotingStatus == VoteStatus.upvoted) {
        return;
      } else if (widget.question.currInterlocutorVotingStatus ==
          VoteStatus.neutral) {
        newStatus = VoteStatus.upvoted;
      } else {
        newStatus = VoteStatus.neutral;
      }
    } else {
      if (widget.question.currInterlocutorVotingStatus ==
          VoteStatus.downvoted) {
        return;
      } else if (widget.question.currInterlocutorVotingStatus ==
          VoteStatus.neutral) {
        newStatus = VoteStatus.downvoted;
      } else {
        newStatus = VoteStatus.neutral;
      }
    }

    final viewModel = Provider.of<QuestionViewModel>(context, listen: false);
    final result = await viewModel.vote(
      widget.question.id,
      widget.question.currInterlocutorVotingStatus,
      newStatus,
    );
    switch (result) {
      case UpdateResult.Updated:
        if (mounted) {
          setState(() {
            voteAction == VoteAction.upvote
                ? cumulativeVotingScore++
                : cumulativeVotingScore--;
            widget.question.currInterlocutorVotingStatus = newStatus;
          });
        }

        break;

      case UpdateResult.AlreadyUpdated:
        break;

      case UpdateResult.FailedToUpdate:
        const snackBar = SnackBar(
          content: Text('Error while voting.'),
        ); // TODO: internationalize
        scaffoldMessenger.showSnackBar(snackBar);
        break;
    }
  }

  Future<void> toggleFavorite() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final newFavoriteStatus = widget.question.isFavorited ?? false
        ? FavoriteState.unfavorite
        : FavoriteState.favorite;
    final viewModel = Provider.of<QuestionViewModel>(context, listen: false);
    final result =
        await viewModel.favoriteQuestion(widget.question.id, newFavoriteStatus);

    switch (result) {
      case UpdateResult.Updated:
        if (mounted) {
          setState(() {
            isFavorited =
                newFavoriteStatus == FavoriteState.favorite ? true : false;
          });
        }
        break;

      case UpdateResult.AlreadyUpdated:
        break;

      case UpdateResult.FailedToUpdate:
        final snackBar = SnackBar(
          content: Text(
            'Error while ${newFavoriteStatus == FavoriteState.favorite ? 'favoriting' : 'unfavoriting'}.',
          ),
        ); // TODO: internationalize
        scaffoldMessenger.showSnackBar(snackBar);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnpublishedDrafts = widget.question.unpublishedDrafts != null &&
        widget.question.unpublishedDrafts!.isNotEmpty;
    final hasPublishedDrafts = widget.question.publishedDrafts != null &&
        widget.question.publishedDrafts!.isNotEmpty;
    const vertSpaceSizedBox = 10.0;

    final bottomActionButtonsRow = Column(
      children: [
        if (hasUnpublishedDrafts || hasPublishedDrafts) ...[
          const SizedBox(
            height: vertSpaceSizedBox,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasUnpublishedDrafts && widget.onSeeChats == null) ...[
                FacePile(
                  avatarSize: 15,
                  separationBorderSize: 2,
                  interlocutors: widget.question.unpublishedDrafts!
                      .map((e) => e.otherInterlocutor)
                      .toList(),
                  text: 'Drafts started for',
                ),
                const SizedBox(
                  width: 40,
                )
              ],
              if (hasPublishedDrafts && widget.onSeeChats == null)
                FacePile(
                  avatarSize: 15,
                  separationBorderSize: 2,
                  interlocutors: widget.question.publishedDrafts!
                      .map((e) => e.otherInterlocutor)
                      .toList(),
                  text: 'Answer published for',
                ),
            ],
          ),
        ],
        const SizedBox(
          height: vertSpaceSizedBox,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: widget.question.currInterlocutorVotingStatus ==
                          VoteStatus.upvoted
                      ? const Icon(FontAwesomeIcons.solidCircleUp)
                      : const Icon(FontAwesomeIcons.circleUp),
                  onPressed: () => onVote(VoteAction.upvote),
                ),
                Text('$cumulativeVotingScore'),
                IconButton(
                  icon: widget.question.currInterlocutorVotingStatus ==
                          VoteStatus.downvoted
                      ? const Icon(FontAwesomeIcons.solidCircleDown)
                      : const Icon(FontAwesomeIcons.circleDown),
                  onPressed: () => onVote(VoteAction.downvote),
                ),
              ],
            ),
            if (!widget.hideAnswerButtons)
              ElevatedButton(
                onPressed: isQuestionAnsweredForAll
                    ? null
                    : () {
                        context.router.push(
                          AnswerQuestionRoute(
                            question: widget.question,
                            allConnectedInterlocutors:
                                widget.allConnectedInterlocutors ?? [],
                            // Create a function that takes the updated question from the answer page, and updates it in the HomeFeedCubit
                          ),
                        );
                      },
                child: Text(buttonText),
              ),
            if (widget.onSeeChats != null)
              ElevatedButton(
                onPressed: () {
                  widget.onSeeChats!();
                },
                child: const Text('See Conversation'),
              ),
            IconButton(
              icon: isFavorited
                  ? const Icon(Icons.favorite)
                  : const Icon(Icons.favorite_border),
              onPressed: toggleFavorite,
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        elevation: 5,
        child: DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).colorScheme.secondaryContainer,
              Theme.of(context).colorScheme.tertiaryContainer,
            ],
          )),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (widget.questionThreadNumNewUnseenMessages != null &&
                        widget.questionThreadNumNewUnseenMessages! > 0) ...[
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
                          widget.questionThreadNumNewUnseenMessages.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ), // Add some spacing between the badge and the names
                    ],
                    Flexible(
                      child: Text(
                        widget.question.content,
                      ),
                    ),
                  ],
                ),
                if (widget.questionThreadUpdatedAt != null) ...[
                  const SizedBox(
                    height: 8, // Add some space
                  ),
                  Row(
                    children: [
                      UpdatedAtTextWidget(
                        updatedAt:
                            DateTime.parse(widget.questionThreadUpdatedAt!),
                      ),
                      if (widget.question.answeredByFriends.isNotEmpty) ...[
                        const SizedBox(
                          width: 10, // Add some space
                        ),
                        Chip(
                          label: Text(
                            'Answered by ${getFriendNamesFromUUIDs(widget.question.answeredByFriends).join(', ')}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        )
                      ]
                      // TODO: show Chip if question already answered by self for someone?
                    ],
                  ),
                  const SizedBox(
                    height: 5, // Add some space
                  ),
                ],
                const SizedBox(height: 5),
                bottomActionButtonsRow,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
