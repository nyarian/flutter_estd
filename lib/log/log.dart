import 'dart:async';

abstract interface class Log {
  void log(String message);

  void logError(Object error, [StackTrace? trace]);
}

class NoOpLog implements Log {
  factory NoOpLog() => const NoOpLog._const();

  const NoOpLog._const();

  @override
  void log(String message) {
    // No-op
  }

  @override
  void logError(Object error, [StackTrace? trace]) {
    // No-op
  }
}

extension LogError on Log {
  T logDirectError<T>(T Function() f) {
    try {
      return f();
    } on Object catch (e, st) {
      logError(e, st);
      rethrow;
    }
  }

  Future<T> logFutureError<T>(Future<T> future) async {
    try {
      return await future;
    } on Object catch (e, st) {
      logError(e, st);
      rethrow;
    }
  }

  Stream<T> logStreamErrors<T>(Stream<T> stream) {
    return stream.transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) {
          logError(error, stackTrace);
          sink.addError(error, stackTrace);
        },
      ),
    );
  }
}
