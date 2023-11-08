import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

const minPasswordLength = 8;
const minAge = 13;

List<QuestionThread> sortQuestionThreadsByDate(
  List<QuestionThread> unsortedQuestionThreads,
) {
  return List<QuestionThread>.from(unsortedQuestionThreads)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

String? passwordLengthValidator(String? password, int minLength) {
  if (password == null || password.isEmpty) {
    return LocaleKeys.passwordCannotBeEmpty.tr().toCapitalized();
  } else if (password.length < minLength) {
    // return LocaleKeys.passwordNotLongEnough.tr().toCapitalized();
    return 'Must contain at least $minLength characters';
  }
  return null;
}

List<Interlocutor> filterInterlocutors({
  required List<Interlocutor> interlocutorsToFilter,
  required Interlocutor? interlocutorToExclude,
}) {
  return interlocutorsToFilter
      .where((interlocutor) => interlocutor.id != interlocutorToExclude?.id)
      .map((interlocutor) => interlocutor)
      .toList();
}

String createNameStrFromInterlocutors(List<Interlocutor> interlocutors) {
  final names = interlocutors.map((i) => i.name).toList();
  if (names.length == 1) {
    return names.first;
  }
  // if the list has 2 strings, return the 2 strings concatenated with "and"
  else if (names.length == 2) {
    return '${names[0]} and ${names[1]}';
  }
  // if there are more than 2, concatenate them with ","
  // for all except the last two with "and"
  else if (names.length > 2) {
    final allExceptLastTwo = names.sublist(0, names.length - 2);
    final lastTwo = names.sublist(names.length - 2);
    final formattedString =
        '${allExceptLastTwo.join(', ')}, ${lastTwo.join(' and ')}';
    return formattedString;
  } else {
    return '';
  }
}

String createInviteMessage({required String inviteeName, required String url}) {
  return '${LocaleKeys.invitationGreeting.tr(
    args: [inviteeName],
  )}! ${LocaleKeys.invitationJoinMeMessage.tr(
    args: [url],
  )}';
}

class VisibilityChangeNotifier {
  VisibilityChangeNotifier({
    required this.thresholdInSeconds,
    required this.onThresholdExceeded,
  }) {
    html.document.addEventListener('visibilitychange', handleVisibilityChange);
  }

  final int thresholdInSeconds;
  final VoidCallback onThresholdExceeded;
  DateTime? lastInvisibleTime;
  bool isThresholdExceededCalled = false; // Add this flag

  void dispose() {
    html.document
        .removeEventListener('visibilitychange', handleVisibilityChange);
  }

  void handleVisibilityChange(html.Event event) {
    if (isThresholdExceededCalled) return; // Check the flag here

    final currentTime = DateTime.now();
    final elapsedTime = lastInvisibleTime != null
        ? currentTime.difference(lastInvisibleTime!)
        : null;

    if (html.document.visibilityState == 'visible') {
      if (elapsedTime != null && elapsedTime.inSeconds >= thresholdInSeconds) {
        onThresholdExceeded();
        isThresholdExceededCalled = true; // Set the flag here
        lastInvisibleTime = null; // Reset lastInvisibleTime
      } else {
        lastInvisibleTime = null; // Reset lastInvisibleTime
      }
    } else if (html.document.visibilityState == 'hidden') {
      lastInvisibleTime = currentTime;
      isThresholdExceededCalled = false; // Reset the flag here
    }
  }
}
