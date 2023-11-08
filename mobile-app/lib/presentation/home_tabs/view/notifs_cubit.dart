import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';

class NotificationCubit extends Cubit<int> {
  NotificationCubit(Stream<int> notificationCountStream) : super(0) {
    logDebug(
      'NotificationCubit - created',
    ); // Log when a new instance is created
    _subscription = notificationCountStream.listen(
      (count) {
        logDebug(
          'NotificationCubit - notification count updated: $count',
        ); // Debug print
        emit(count);
      },
      onError: (error) {
        logError(
          'NotificationCubit - error in stream: $error',
        );
      },
    );
  }
  StreamSubscription<int>? _subscription;

  @override
  Future<void> close() {
    logDebug(
      'NotificationCubit - closing',
    ); // Log before closing
    _subscription?.cancel().then(
          (_) => logDebug(
            'NotificationCubit - subscription cancelled',
          ),
        ); // Log when the subscription is cancelled
    return super.close();
  }
}
