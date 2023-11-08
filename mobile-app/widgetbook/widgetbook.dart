import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';
import 'package:chatbond/presentation/chats/chats/answer_question/answer_question_page.dart';
import 'package:chatbond/presentation/profile/view/shared_widgets/profile_header.dart';
import 'package:chatbond/presentation/shared_widgets/chat_thread_card.dart';
import 'package:chatbond/presentation/shared_widgets/invitation_widget.dart';
import 'package:chatbond/presentation/shared_widgets/live_editable_field/live_editable_field.dart';
import 'package:chatbond/presentation/shared_widgets/menu_item.dart';
import 'package:chatbond/presentation/shared_widgets/profile_pic.dart';
import 'package:chatbond/presentation/shared_widgets/question_card.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:widgetbook/widgetbook.dart';

class WidgetbookHotReload extends StatelessWidget {
  WidgetbookHotReload({super.key});

  final interlocutor1 = Interlocutor(
    id: '1',
    userId: '1',
    name: 'Mike Ross',
    username: 'mikyross',
    email: 'mike@ross.com',
    createdAt: DateTime.now().toString(),
  );
  final interlocutor2 = Interlocutor(
    id: '2',
    userId: '2',
    name: 'Josianne Balasko',
    username: 'balasko',
    email: 'jo@balasko.com',
    createdAt: DateTime.now().toString(),
  );
  final interlocutor3 = Interlocutor(
    id: '3',
    userId: '3',
    name: 'Lu Jo',
    username: 'Jolu',
    email: 'lulu@bulu.com',
    createdAt: DateTime.now().toString(),
  );
  final interlocutor4 = Interlocutor(
    id: '4',
    userId: '4',
    name: 'Mark Buffalo',
    username: 'dasbuff',
    email: 'mark@buff.com',
    createdAt: DateTime.now().toString(),
  );

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        WidgetbookCategory(
          name: 'Questions',
          children: [
            WidgetbookComponent(
              name: 'QuestionCard',
              useCases: [
                WidgetbookUseCase(
                  name: 'To answer',
                  builder: (context) => QuestionCard(
                    question: Question(
                      id: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
                      content:
                          'If you could change something about yourself, what would it be and why?',
                      cumulativeVotingScore: 12,
                      timesVoted: 23,
                      timesAnswered: 41,
                      createdAt: DateTime.now().toString(),
                      updatedAt: DateTime.now().toString(),
                      isFavorited: true,
                      answeredByFriends: const [],
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Draft',
                  builder: (context) => QuestionCard(
                    question: Question(
                      id: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
                      content:
                          'If you could change something about yourself, what would it be and why?',
                      cumulativeVotingScore: 12,
                      timesVoted: 23,
                      timesAnswered: 41,
                      createdAt: DateTime.now().toString(),
                      updatedAt: DateTime.now().toString(),
                      isFavorited: true,
                      answeredByFriends: const [],
                      unpublishedDrafts: [
                        DraftQuestionThread(
                          content: '',
                          question: '',
                          otherInterlocutor: interlocutor1,
                        ),
                        DraftQuestionThread(
                          content: '',
                          question: '',
                          otherInterlocutor: interlocutor2,
                        ),
                      ],
                      publishedDrafts: [
                        DraftQuestionThread(
                          content: '',
                          question: '',
                          otherInterlocutor: interlocutor3,
                        ),
                        DraftQuestionThread(
                          content: '',
                          question: '',
                          otherInterlocutor: interlocutor4,
                        ),
                      ],
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'No answer option',
                  builder: (context) => QuestionCard(
                    hideAnswerButtons: true,
                    question: Question(
                      id: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
                      content:
                          'If you could change something about yourself, what would it be and why?',
                      cumulativeVotingScore: 12,
                      timesVoted: 23,
                      timesAnswered: 41,
                      createdAt: DateTime.now().toString(),
                      updatedAt: DateTime.now().toString(),
                      isFavorited: true,
                      answeredByFriends: const [],
                    ),
                  ),
                ),
                // WidgetbookUseCase(
                //   // TODO
                //   name: 'Self answered',
                //   // TODO
                //   builder: (context) => QuestionCard(
                //     question: Question(
                //       id: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
                //       content:
                //           'If you could change something about yourself, what would it be and why?',
                //       cumulativeVotingScore: 12,
                //       timesVoted: 23,
                //       timesAnswered: 41,
                //       createdAt: DateTime.now().toString(),
                //       updatedAt: DateTime.now().toString(),
                //       isFavorited: true,
                //     ),
                //   ),
                // ),
                WidgetbookUseCase(
                  // TODO
                  name: 'Other answered',
                  builder: (context) => QuestionCard(
                    question: Question(
                      id: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
                      content:
                          'If you could change something about yourself, what would it be and why?',
                      cumulativeVotingScore: 12,
                      timesVoted: 23,
                      timesAnswered: 41,
                      createdAt: DateTime.now().toString(),
                      updatedAt: DateTime.now().toString(),
                      isFavorited: true,
                      answeredByFriends: [],
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  // TODO
                  name: 'Both answered',
                  builder: (context) => QuestionCard(
                    question: Question(
                      id: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
                      content:
                          'If you could change something about yourself, what would it be and why?',
                      cumulativeVotingScore: 12,
                      timesVoted: 23,
                      timesAnswered: 41,
                      createdAt: DateTime.now().toString(),
                      updatedAt: DateTime.now().toString(),
                      isFavorited: true,
                      answeredByFriends: const [],
                    ),
                    onSeeChats: () {},
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'AnswerQuestionWidget',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => AnswerQuestionWidget(
                    question: Question(
                      id: '1',
                      timesVoted: 5,
                      timesAnswered: 23,
                      createdAt: DateTime.now().toString(),
                      updatedAt: DateTime.now().toString(),
                      content:
                          'What would you like to be doing as a career in 5 years?',
                      cumulativeVotingScore: 4,
                      answeredByFriends: const [],
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'FacePile',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => FacePile(
                    avatarSize: 10,
                    interlocutors: [
                      interlocutor1,
                      interlocutor2,
                      interlocutor3,
                      interlocutor4,
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Chats',
          children: [
            WidgetbookComponent(
              name: 'ChatThreadCard',
              useCases: [
                WidgetbookUseCase(
                  name: 'No notifications',
                  builder: (context) => ChatThreadCard(
                    interlocutor: Interlocutor(
                      id: '1',
                      userId: '1',
                      name: 'Mike',
                      username: 'mikyross',
                      email: 'mike@ross.com',
                      createdAt: DateTime.now().toString(),
                    ),
                    updatedAt: DateTime.now(),
                    numUnseenMessages: 0,
                    onWidgetTap: () {},
                    numAnswerableQuestions: 3,
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Has notifications',
                  builder: (context) => ChatThreadCard(
                    interlocutor: Interlocutor(
                      id: '1',
                      userId: '1',
                      name: 'Mike',
                      username: 'mikyross',
                      email: 'mike@ross.com',
                      createdAt: DateTime.now().toString(),
                    ),
                    updatedAt: DateTime.now(),
                    numUnseenMessages: 3,
                    onWidgetTap: () {},
                    numAnswerableQuestions: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Invitation',
          children: [
            WidgetbookComponent(
              name: 'InvitationsCRUDWidget',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => InvitationsCRUDWidget(
                    inviteButtonLabel: 'Create Invitation',
                    acceptInviteButtonLabel: 'Accept Invitation',
                    onCreateInvitePressed: () {},
                    onManuallyAcceptInvitePressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Profile',
          children: [
            WidgetbookComponent(
              name: 'Menu item',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => MenuItem(
                    title: 'Favorites',
                    iconData: Icons.favorite,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Profile header',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => ProfileHeaderWidget(
                    onEditClicked: () {},
                    email: 'example@gmail.com',
                    username: 'Jo Bandie',
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Editable',
                  builder: (context) => ProfileHeaderWidget(
                    onEditClicked: () {},
                    email: 'example@gmail.com',
                    username: 'Jo Bandie',
                    isEdit: true,
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Editing Field',
              useCases: [
                WidgetbookUseCase(
                  name: 'Editable, cannot be empty',
                  builder: (context) => LiveEditableField(
                    title: 'Name',
                    initialContent: 'Joe Dalton',
                    allowEdits: true,
                    onSave: (val) async {},
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Editable, can be empty',
                  builder: (context) => LiveEditableField(
                    title: 'Name',
                    initialContent: 'Joe Dalton',
                    allowEdits: true,
                    allowEmpty: true,
                    onSave: (val) async {},
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Non-editable',
                  builder: (context) => LiveEditableField(
                    title: 'Name',
                    initialContent: 'Joe Dalton',
                    onSave: (val) async {},
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Bottom navbar',
              useCases: [
                WidgetbookUseCase(
                  name: 'default',
                  builder: (context) => SalomonBottomBar(
                    itemPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    margin: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).size.width > 700
                          ? MediaQuery.of(context).size.width / 3
                          : 40,
                      5,
                      MediaQuery.of(context).size.width > 700
                          ? MediaQuery.of(context).size.width / 3
                          : 40,
                      10,
                    ),
                    items: [
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.home),
                        title: const Text('Home'),
                        selectedColor: Colors.purple,
                      ),

                      /// Friends
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.free_breakfast),
                        title: const Text('Friends'),
                        selectedColor: Colors.pink,
                      ),

                      /// Profile
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.person),
                        title: const Text('Profile'),
                        selectedColor: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
