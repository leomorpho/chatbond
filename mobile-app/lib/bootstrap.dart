import 'dart:async';
import 'dart:developer';

import 'package:chatbond/app/app.dart';
import 'package:chatbond/config/hydrated_storage.dart';
import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/config/push_notifications.dart';
import 'package:chatbond/data/db/hive/chat_thread.dart';
import 'package:chatbond/data/db/hive/interlocutor.dart';
import 'package:chatbond/data/db/hive/question_chat.dart';
import 'package:chatbond/data/db/hive/question_chat_interaction_event.dart';
import 'package:chatbond/data/db/hive/question_thread.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/data/repositories/secure_storage_repo.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const hiveChatThreadsBoxKey = 'chat_threads';
const hiveQuestionThreadsBoxKey = 'question_threads';
const hiveQuestionChatsBoxKey = 'question_chats';
const hiveInterlocutorBoxKey = 'interlocutors';

late String oneSignalKey;

class ChatProvider extends ChangeNotifier {
  /// Streams to communicate between real time repo and hive repo.
  /// These allow decoupling both pieces entirely.
  final chatThreadsController = BehaviorSubject<List<ChatThread>>();
  final questionThreadsController = BehaviorSubject<List<QuestionThread>>();
  final questionChatsController = BehaviorSubject<List<QuestionChat>>();
  final interlocutorsController = BehaviorSubject<List<Interlocutor>>();

  /// Used to update the total num of notifications in the tab bar.
  final numTotalNotificationsController = BehaviorSubject<int>.seeded(0);

  /// Streams to communicate object requests from FE to BE, where
  /// hive repo can communicate back with other repos to keep the local
  /// DB in a consistent state. If a new object comes in to the FE but a
  /// parent object is not present, the new object will be persisted in
  /// local DB and a new request we be dispatched to the BE to query the
  /// missing parent object. When the new parent object is processed, any
  /// inter-object links can be re-established.
  final chatThreadRequestsController = BehaviorSubject<String>();
  final questionThreadRequestsController = BehaviorSubject<String>();
  final interlocutorRequestsController = BehaviorSubject<String>();

  @override
  void dispose() {
    chatThreadsController.close();
    questionThreadsController.close();
    questionChatsController.close();
    interlocutorsController.close();
    numTotalNotificationsController.close();
    chatThreadRequestsController.close();
    questionThreadRequestsController.close();
    interlocutorRequestsController.close();
    super.dispose();
  }
}

class AppBlocObserver extends BlocObserver with BlocLogger {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // if (kDebugMode) {
    //   loggy.debug('onChange(${bloc.runtimeType}, $change)');
    // }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      loggy.error('onError(${bloc.runtimeType}, $error, $stackTrace)');
    }
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap() async {
  if (kReleaseMode) {
    // Only initialize Sentry in release mode
    await SentryFlutter.init(
      (options) {
        options
          ..dsn =
              'https://6cf6318811bbb38865275e8ea02f7a78@o4505031789314048.ingest.sentry.io/4505852471148544'
          ..tracesSampleRate = 1.0;
        // any other Sentry options you'd like to configure
      },
      appRunner: bootstrapRun,
    );
  } else {
    bootstrapRun(); // Run the app normally in debug mode
  }
}

FutureOr<void> bootstrapRun() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  if (kReleaseMode) {
    FlutterError.onError = (details) {
      Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );
    };
    Loggy.initLoggy(
      logPrinter: const PrettyPrinter(),
      logOptions: const LogOptions(LogLevel.off, callerFrameDepthLevel: 0),
      filters: [
        BlacklistFilter([BlocLogger]),
      ],
    );
  } else {
    FlutterError.onError = (details) {
      log(details.exceptionAsString(), stackTrace: details.stack);
    };
    Loggy.initLoggy(
      logPrinter: const PrettyPrinter(),
      filters: [
        BlacklistFilter([BlocLogger]),
      ],
    );
  }

  Bloc.observer = AppBlocObserver();

  if (kReleaseMode) {
    await dotenv.load(fileName: 'envproduction');
  } else {
    await dotenv.load(fileName: '.env.development');
  }
  late String chatbondApiUrl;

  if (!kIsWeb) {
    chatbondApiUrl = dotenv.get('API_URL_MOBILE');
    oneSignalKey = dotenv.get('ONE_SIGNAL_APP_ID');
    if (oneSignalKey.isEmpty) {
      throw StateError('missing environment variable <ONE_SIGNAL_APP_ID>');
    }
    initPushNotifications(oneSignalKey);
  } else {
    chatbondApiUrl = dotenv.get('API_URL_WEB');
  }

  if (chatbondApiUrl.isEmpty) {
    throw StateError('missing environment variable <API_URL_MOBILE>');
  }

  const secureStorage = FlutterSecureStorage();

  await Hive.initFlutter();

  // To reset Hive due to adapter changes:
  // 1. Uncomment the following
  // 2. Run the UI (will fail, cached Hive now deleted. Note that if run on web,
  //    only relevant port is cleaned up.)
  // 3. Comment it out again
  // 4. Run the UI (will work)
  // await Hive.deleteFromDisk();

  Hive
    ..registerAdapter<HiveChatThread>(HiveChatThreadAdapter())
    ..registerAdapter<HiveQuestionThread>(HiveQuestionThreadAdapter())
    ..registerAdapter<HiveQuestionChat>(HiveQuestionChatAdapter())
    ..registerAdapter<HiveInterlocutor>(HiveInterlocutorAdapter())
    ..registerAdapter<HiveQuestionChatInteractionEvent>(
      HiveQuestionChatInteractionEventAdapter(),
    );
  /***
 * NOTE: If needed, reset secure storage
 * This is often necessary when stuck on the splash screen
 * on hot reload or even first bootup.
 */
  // await secureStorage.deleteAll();

  // TODO: not great how we pass the whole of api_client to each one of the repos
  // Service providers
  getIt.registerSingleton<SecureStorageRepo>(
    SecureStorageRepo(secureStorage),
  );

  final client = ApiClient(
    baseUrl: chatbondApiUrl,
    realtimeUrl: dotenv.get(
      'CENTRIFUGE_SERVER_ADDRESS',
    ),
    persistAccessToken: (String? token) async {
      await getIt.get<SecureStorageRepo>().persistAccessToken(token);
    },
    persistRefreshToken: (String? token) async {
      await getIt.get<SecureStorageRepo>().persistRefreshToken(token);
    },
    getAccessTokenFromCookie: () async {
      return getIt.get<SecureStorageRepo>().getAccessToken();
    },
    getRefreshTokenFromCookie: () async {
      return getIt.get<SecureStorageRepo>().getRefreshToken();
    },
  );
  await client.init();

  getIt
    ..registerSingleton<ApiClient>(client)
    ..registerSingleton<GlobalState>(GlobalState());

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  await initHydratedBlocStorage();

  await runZonedGuarded(
    () async => runApp(
      // TODO: i18 requires specific setup on iOS that I haven't done yet (ios/Runner/Info.plist)
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        path: 'assets/translations/translations.csv',
        fallbackLocale: const Locale('en', 'US'),
        assetLoader: CsvAssetLoader(),
        child: const App(),
      ),
    ),
    (error, stackTrace) {
      if (kReleaseMode) {
        Sentry.captureException(error, stackTrace: stackTrace);
      }
      log(error.toString(), stackTrace: stackTrace);
    },
  );
}
