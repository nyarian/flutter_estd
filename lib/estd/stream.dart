import 'dart:typed_data';

import 'package:async/async.dart';

class FixedIntStream {
  FixedIntStream(this.stream, this.length);

  final Stream<Uint8List> stream;
  final int length;
}

class StreamBuffer<T> {
  StreamBuffer(this._stream);

  Future<List<Result<T>>> buffer() => Result.captureStream(_stream).toList();

  final Stream<T> _stream;
}
