import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

abstract interface class FlutterErrorHandlingPolicy {
  void call(FlutterErrorDetails details);
}

class DumpErrorHandlerDecorator implements FlutterErrorHandlingPolicy {
  const DumpErrorHandlerDecorator(this._decorated);

  const DumpErrorHandlerDecorator.noOp() : _decorated = const NoOpPolicy();

  @override
  void call(FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    _decorated(details);
  }

  final FlutterErrorHandlingPolicy _decorated;
}

class NoOpPolicy implements FlutterErrorHandlingPolicy {
  const NoOpPolicy();

  @override
  void call(FlutterErrorDetails details) {
    // No-op
  }
}

class ExitOnMobileReleasePolicy implements FlutterErrorHandlingPolicy {
  const ExitOnMobileReleasePolicy();

  @override
  void call(FlutterErrorDetails details) {
    if (kReleaseMode &&
        !kIsWeb &&
        details.exception is! SocketException &&
        details.exception is! NetworkImageLoadException) {
      exit(1);
    }
  }
}
