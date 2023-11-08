import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

// @RoutePage()
// class ChatThreadsRouter extends StatelessWidget {
//   const ChatThreadsRouter({
//     super.key,
//     @PathParam('questionThread') required this.questionThreadId,
//   });

//   final String questionThreadId;

//   @override
//   Widget build(BuildContext context) {
//     return const AutoRouter();
//   }
// }

@RoutePage()
class QuestionThreadsRouter extends StatelessWidget {
  const QuestionThreadsRouter({
    super.key,
    @PathParam('questionThread') required this.questionThreadId,
  });

  final String questionThreadId;

  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}
