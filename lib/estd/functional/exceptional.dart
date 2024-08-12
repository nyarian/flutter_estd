import 'package:flutter_estd/estd/functional/std.dart';
import 'package:meta/meta.dart';

@immutable
abstract interface class Exceptional<T> {
  factory Exceptional.of(Producer<T> producer) {
    try {
      return _Success(producer());
    } on Object catch (e) {
      return _Failure(e);
    }
  }

  Exceptional<R> map<R>(Transformation<T, R> function);

  Exceptional<R> flatMap<R>(Transformation<T, Exceptional<R>> function);

  T fold({required Transformation<Object, T> onError});
}

@immutable
class _Success<T> implements Exceptional<T> {
  const _Success(this._value);

  @override
  Exceptional<R> map<R>(Transformation<T, R> function) =>
      _Success(function(_value));

  @override
  Exceptional<R> flatMap<R>(Transformation<T, Exceptional<R>> function) =>
      function(_value);

  @override
  T fold({required Transformation<Object, T> onError}) => _value;

  final T _value;
}

@immutable
class _Failure<T> implements Exceptional<T> {
  const _Failure(this._error);

  @override
  Exceptional<R> map<R>(Transformation<T, R> function) => _Failure(_error);

  @override
  Exceptional<R> flatMap<R>(Transformation<T, Exceptional<R>> function) =>
      _Failure(_error);

  @override
  T fold({required Transformation<Object, T> onError}) => onError(_error);

  final Object _error;
}
