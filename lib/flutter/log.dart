import 'package:flutter/foundation.dart';
import 'package:flutter_estd/log/log.dart';

class FlutterLog implements Log {
  const FlutterLog();

  @override
  void log(String message) {
    debugPrint(message);
  }

  @override
  void logError(Object error, [StackTrace? trace]) {
    log(error.toString());
    if (trace != null) log(trace.toString());
  }
}
