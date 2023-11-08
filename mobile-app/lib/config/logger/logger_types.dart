import 'package:loggy/loggy.dart';

mixin RepoLogger implements LoggyType {
  @override
  Loggy<RepoLogger> get loggy => Loggy<RepoLogger>('RepoLogger - $runtimeType');
}

mixin DataSourceLogger implements LoggyType {
  @override
  Loggy<DataSourceLogger> get loggy =>
      Loggy<DataSourceLogger>('DataSourceLogger - $runtimeType');
}

mixin BlocLogger implements LoggyType {
  @override
  Loggy<DataSourceLogger> get loggy =>
      Loggy<DataSourceLogger>('BlocLogger - $runtimeType');

  // void logInfo(dynamic message, [Object? error, StackTrace? stackTrace]) =>
  //     loggy.info(message, error, stackTrace);

  // void logWarning(dynamic message, [Object? error, StackTrace? stackTrace]) =>
  //     loggy.warning(message, error, stackTrace);

  // void logError(dynamic message, [Object? error, StackTrace? stackTrace]) =>
  //     loggy.error(message, error, stackTrace);
}
