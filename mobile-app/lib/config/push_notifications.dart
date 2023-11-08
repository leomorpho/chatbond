import 'package:onesignal_flutter/onesignal_flutter.dart';

void initPushNotifications(String oneSignalKey) {
  OneSignal.initialize(oneSignalKey);

  // TODO: might need to call the below in login after logging in user to onesignal
  OneSignal.User.pushSubscription.optIn();
}
