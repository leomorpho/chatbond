import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:chatbond/constants.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/questions_repo/questions_repo.dart';
import 'package:chatbond/presentation/home_feed/cubit/home_feed_cubit.dart';
import 'package:chatbond/presentation/shared_widgets/bottom_loader.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/question_card.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:swipable_stack/swipable_stack.dart';

@RoutePage()
class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeFeedCubit(
        questionsRepo: context.read<QuestionsRepo>(),
        chatsRepo: context.read<ChatThreadsRepo>(),
      )..loadHomeFeed(),
      child: const HomeFeedView(),
    );
  }
}

class HomeFeedView extends StatefulWidget {
  const HomeFeedView({super.key});

  @override
  HomeFeedViewState createState() => HomeFeedViewState();
}

class HomeFeedViewState extends State<HomeFeedView> {
  final _scrollController = ScrollController();
  StreamSubscription<HomeFeedState>? _blocSubscription;

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
    _blocSubscription = BlocProvider.of<HomeFeedCubit>(context).stream.listen(
      (state) {
        // Just by listening to the bloc state in didChangeDependencies,
        // we ensure that the widget rebuilds when it comes back into view
        // and a new state has been emitted.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      body: MaxWidthView(
        child: BlocBuilder<HomeFeedCubit, HomeFeedState>(
          builder: (context, state) {
            if (state is HomeFeedLoading) {
              return const LoadingDialog();
            } else if (state is HomeFeedError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(
                      height: 16,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Call fetchQuestions when the button is pressed
                        context
                            .read<HomeFeedCubit>()
                            .loadHomeFeed(reloadFromStart: true);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is HomeFeedLoaded) {
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                    create: (context) => QuestionViewModel(
                      questionsRepo: context.read<QuestionsRepo>(),
                    ),
                  ),
                ],
                child: Column(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Your daily questions from ${DateFormat('yMMMd').format(state.feedGenerationDatetime)}',
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // ignore: prefer_if_elements_to_conditional_expressions
                    (isMobile && isSwipeableCardsSwitchEnabled)
                        ? SwipeableCards(
                            questions: state.questions,
                            connectedInterlocutors:
                                state.allConnectedInterlocutors,
                          )
                        : Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: state.hasReachedMax
                                  ? state.questions.length
                                  : state.questions.length,
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
                                        state.allConnectedInterlocutors,
                                  );
                                }
                              },
                            ),
                          ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink(); // For the initial state
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _blocSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final state = BlocProvider.of<HomeFeedCubit>(context).state;
    if (_isBottom && state is HomeFeedLoaded && !state.hasReachedMax) {
      BlocProvider.of<HomeFeedCubit>(context).loadHomeFeed();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.75);
  }
}

class SwipeableCards extends StatefulWidget {
  const SwipeableCards({
    super.key,
    required this.questions,
    required this.connectedInterlocutors,
  });

  final List<Question> questions;
  final List<Interlocutor>? connectedInterlocutors;

  @override
  State<SwipeableCards> createState() => _SwipeableCardsState();
}

class _SwipeableCardsState extends State<SwipeableCards> {
  late final SwipableStackController _controller;

  void _listenController() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = SwipableStackController()..addListener(_listenController);
  }

  @override
  void dispose() {
    super.dispose();
    _controller
      ..removeListener(_listenController)
      ..dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SwipableStack(
                controller: _controller,
                stackClipBehaviour: Clip.none,
                allowVerticalSwipe: false,
                onWillMoveNext: (index, swipeDirection) {
                  // Return true for the desired swipe direction.
                  switch (swipeDirection) {
                    case SwipeDirection.left:
                    case SwipeDirection.right:
                      return true;
                    case SwipeDirection.up:
                    case SwipeDirection.down:
                      return false;
                  }
                },
                onSwipeCompleted: (index, direction) {
                  if (kDebugMode) {
                    print('$index, $direction');
                  }
                },
                horizontalSwipeThreshold: 0.8,
                // Set max value to ignore vertical threshold.
                verticalSwipeThreshold: 1,
                overlayBuilder: (
                  context,
                  properties,
                ) =>
                    CardOverlay(
                  swipeProgress: properties.swipeProgress,
                  direction: properties.direction,
                ),
                builder: (context, properties) {
                  final itemIndex = properties.index % widget.questions.length;
                  return ExampleCard(
                    name: 'Sample No.${itemIndex + 1}',
                    question: widget.questions[itemIndex],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CardOverlay extends StatelessWidget {
  const CardOverlay({
    required this.direction,
    required this.swipeProgress,
    super.key,
  });
  final SwipeDirection direction;
  final double swipeProgress;

  @override
  Widget build(BuildContext context) {
    final opacity = math.min<double>(swipeProgress, 1);

    final isRight = direction == SwipeDirection.right;
    final isLeft = direction == SwipeDirection.left;
    final isUp = direction == SwipeDirection.up;
    final isDown = direction == SwipeDirection.down;
    return Stack(
      children: [
        Opacity(
          opacity: isRight ? opacity : 0,
          child: CardLabel.right(),
        ),
        Opacity(
          opacity: isLeft ? opacity : 0,
          child: CardLabel.left(),
        ),
        Opacity(
          opacity: isUp ? opacity : 0,
          child: CardLabel.up(),
        ),
        Opacity(
          opacity: isDown ? opacity : 0,
          child: CardLabel.down(),
        ),
      ],
    );
  }
}

const _labelAngle = math.pi / 2 * 0.2;

class CardLabel extends StatelessWidget {
  const CardLabel._({
    required this.color,
    required this.label,
    required this.angle,
    required this.alignment,
  });

  factory CardLabel.right() {
    return const CardLabel._(
      color: SwipeDirectionColor.right,
      label: 'RIGHT',
      angle: -_labelAngle,
      alignment: Alignment.topLeft,
    );
  }

  factory CardLabel.left() {
    return const CardLabel._(
      color: SwipeDirectionColor.left,
      label: 'LEFT',
      angle: _labelAngle,
      alignment: Alignment.topRight,
    );
  }

  factory CardLabel.up() {
    return const CardLabel._(
      color: SwipeDirectionColor.up,
      label: 'UP',
      angle: _labelAngle,
      alignment: Alignment(0, 0.5),
    );
  }

  factory CardLabel.down() {
    return const CardLabel._(
      color: SwipeDirectionColor.down,
      label: 'DOWN',
      angle: -_labelAngle,
      alignment: Alignment(0, -0.75),
    );
  }

  final Color color;
  final String label;
  final double angle;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(
        vertical: 36,
        horizontal: 36,
      ),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: color,
              width: 4,
            ),
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: color,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class ExampleCard extends StatelessWidget {
  const ExampleCard({
    required this.name,
    required this.question,
    super.key,
  });

  final String name;
  final Question question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      child: Stack(
        children: [
          // Positioned.fill(
          //   child: DecoratedBox(
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(14),
          //       image: DecorationImage(
          //         image: AssetImage(assetPath),
          //         fit: BoxFit.cover,
          //       ),
          //       boxShadow: [
          //         BoxShadow(
          //           offset: const Offset(0, 2),
          //           blurRadius: 26,
          //           color: Colors.black.withOpacity(0.08),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          Text(question.content),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black12.withOpacity(0),
                    Colors.black12.withOpacity(.4),
                    Colors.black12.withOpacity(.82),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.headline6!.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: BottomButtonsRow.height),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BottomButtonsRow extends StatelessWidget {
  const BottomButtonsRow({
    required this.onRewindTap,
    required this.onSwipe,
    required this.canRewind,
    super.key,
  });

  final bool canRewind;
  final VoidCallback onRewindTap;
  final ValueChanged<SwipeDirection> onSwipe;

  static const double height = 100;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BottomButton(
                color: canRewind ? Colors.amberAccent : Colors.grey,
                onPressed: canRewind ? onRewindTap : null,
                child: const Icon(Icons.refresh),
              ),
              _BottomButton(
                color: SwipeDirectionColor.left,
                child: const Icon(Icons.arrow_back),
                onPressed: () {
                  onSwipe(SwipeDirection.left);
                },
              ),
              _BottomButton(
                color: SwipeDirectionColor.up,
                onPressed: () {
                  onSwipe(SwipeDirection.up);
                },
                child: const Icon(Icons.arrow_upward),
              ),
              _BottomButton(
                color: SwipeDirectionColor.right,
                onPressed: () {
                  onSwipe(SwipeDirection.right);
                },
                child: const Icon(Icons.arrow_forward),
              ),
              _BottomButton(
                color: SwipeDirectionColor.down,
                onPressed: () {
                  onSwipe(SwipeDirection.down);
                },
                child: const Icon(Icons.arrow_downward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.onPressed,
    required this.child,
    required this.color,
  });

  final VoidCallback? onPressed;
  final Icon child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: 64,
      child: ElevatedButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.resolveWith(
            (states) => RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) => color,
          ),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

class SwipeDirectionColor {
  static const right = Color.fromRGBO(70, 195, 120, 1);
  static const left = Color.fromRGBO(220, 90, 108, 1);
  static const up = Color.fromRGBO(83, 170, 232, 1);
  static const down = Color.fromRGBO(154, 85, 215, 1);
}

extension SwipeDirecionX on SwipeDirection {
  Color get color {
    switch (this) {
      case SwipeDirection.right:
        return const Color.fromRGBO(70, 195, 120, 1);
      case SwipeDirection.left:
        return const Color.fromRGBO(220, 90, 108, 1);
      case SwipeDirection.up:
        return const Color.fromRGBO(83, 170, 232, 1);
      case SwipeDirection.down:
        return const Color.fromRGBO(154, 85, 215, 1);
    }
  }
}
