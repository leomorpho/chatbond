// test/test_plugin_register.dart
import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class TestPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String> getTemporaryPath() {
    return Future.value(Directory.systemTemp.path);
  }

  @override
  Future<Directory> getApplicationDocumentsDirectory() {
    return Future.value(Directory.systemTemp);
  }

  @override
  Future<Directory> getLibraryDirectory() {
    return Future.value(Directory.systemTemp);
  }
}

void registerPathProviderMocks() {
  PathProviderPlatform.instance = TestPathProviderPlatform();
}
