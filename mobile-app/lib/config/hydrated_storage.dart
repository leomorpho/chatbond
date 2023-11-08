import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initHydratedBlocStorage() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage for Android and iOS
  if (!kIsWeb) {
    final directory = await getApplicationDocumentsDirectory();
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: directory,
    );
  } else {
    // Initialize storage for Web
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorage.webStorageDirectory,
    );
  }
  // If needed:
  await HydratedBloc.storage.clear();
}
